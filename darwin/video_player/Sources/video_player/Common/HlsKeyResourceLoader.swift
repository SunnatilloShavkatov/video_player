//
//  HlsKeyResourceLoader.swift
//  video_player
//

import AVFoundation
import Foundation

/// Plays AES-128 HLS whose key endpoint requires request headers (e.g. `Authorization: Bearer`).
///
/// AVFoundation has no API for headers on `#EXT-X-KEY` requests, and a resource loader
/// delegate is only consulted for non-http(s) schemes. The loader therefore:
/// - serves playlists under the `vphls` scheme, rewriting variant/rendition URIs to `vphls`
///   and key URIs to `vpkey`;
/// - makes segment and `#EXT-X-MAP` URIs absolute https, so media bytes bypass the delegate;
/// - fetches `vpkey` URIs over https with the configured headers.
///
/// `AVAssetResourceLoader` holds its delegate weakly — keep the returned loader alive for as
/// long as the asset is playing.
final class HlsKeyResourceLoader: NSObject, AVAssetResourceLoaderDelegate {
    private static let playlistScheme = "vphls"
    private static let keyScheme = "vpkey"
    private static let errorDomain = "uz.plugin.video_player.HlsKeyResourceLoader"

    private let keyHeaders: [String: String]
    private let session = URLSession(configuration: .default)
    private let queue = DispatchQueue(label: "uz.plugin.video_player.hls-key-loader")
    // Accessed on `queue` only.
    private var keyCache: [URL: Data] = [:]
    private var tasks: [AVAssetResourceLoadingRequest: URLSessionDataTask] = [:]

    private init(keyHeaders: [String: String]) {
        self.keyHeaders = keyHeaders
    }

    deinit {
        session.invalidateAndCancel()
    }

    /// Returns a plain asset when there are no headers or the URL is not an https HLS playlist.
    static func makeAsset(url: URL, keyHeaders: [String: String]) -> (asset: AVURLAsset, loader: HlsKeyResourceLoader?) {
        guard !keyHeaders.isEmpty,
              url.absoluteString.lowercased().contains(".m3u8"),
              let proxiedURL = replacingScheme(of: url, from: "https", to: playlistScheme) else {
            return (AVURLAsset(url: url), nil)
        }
        let loader = HlsKeyResourceLoader(keyHeaders: keyHeaders)
        let asset = AVURLAsset(url: proxiedURL)
        asset.resourceLoader.setDelegate(loader, queue: loader.queue)
        return (asset, loader)
    }

    // MARK: - AVAssetResourceLoaderDelegate

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        guard let url = loadingRequest.request.url else { return false }
        switch url.scheme {
        case Self.playlistScheme:
            guard let httpsURL = Self.replacingScheme(of: url, from: Self.playlistScheme, to: "https") else { return false }
            loadPlaylist(from: httpsURL, for: loadingRequest)
        case Self.keyScheme:
            guard let httpsURL = Self.replacingScheme(of: url, from: Self.keyScheme, to: "https") else { return false }
            loadKey(from: httpsURL, for: loadingRequest)
        default:
            return false
        }
        return true
    }

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        tasks.removeValue(forKey: loadingRequest)?.cancel()
    }

    // MARK: - Loading

    private func loadPlaylist(from url: URL, for loadingRequest: AVAssetResourceLoadingRequest) {
        startTask(URLRequest(url: url), for: loadingRequest) { data, response in
            guard let text = String(data: data, encoding: .utf8) else {
                throw Self.error(code: -1, "Playlist is not UTF-8")
            }
            let rewritten = Self.rewrite(playlist: text, baseURL: response.url ?? url)
            return Data(rewritten.utf8)
        }
    }

    private func loadKey(from url: URL, for loadingRequest: AVAssetResourceLoadingRequest) {
        if let cached = keyCache[url] {
            loadingRequest.dataRequest?.respond(with: cached)
            loadingRequest.finishLoading()
            return
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        keyHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        startTask(request, for: loadingRequest) { [weak self] data, _ in
            guard !data.isEmpty else { throw Self.error(code: -1, "Empty AES key response") }
            self?.keyCache[url] = data
            return data
        }
    }

    /// Runs `request` and finishes `loadingRequest` with the (optionally transformed) body.
    /// `transform` runs on `queue`.
    private func startTask(
        _ request: URLRequest,
        for loadingRequest: AVAssetResourceLoadingRequest,
        transform: @escaping (Data, HTTPURLResponse) throws -> Data
    ) {
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            self.queue.async {
                // Missing entry means the request was cancelled meanwhile.
                guard self.tasks.removeValue(forKey: loadingRequest) != nil,
                      !loadingRequest.isCancelled else { return }
                do {
                    if let error = error { throw error }
                    guard let http = response as? HTTPURLResponse, let data = data else {
                        throw Self.error(code: -1, "No HTTP response")
                    }
                    guard (200..<300).contains(http.statusCode) else {
                        throw Self.error(code: http.statusCode, "HTTP \(http.statusCode) for \(request.url?.path ?? "")")
                    }
                    loadingRequest.dataRequest?.respond(with: try transform(data, http))
                    loadingRequest.finishLoading()
                } catch {
                    loadingRequest.finishLoading(with: error)
                }
            }
        }
        tasks[loadingRequest] = task
        task.resume()
    }

    // MARK: - Playlist rewriting

    static func rewrite(playlist: String, baseURL: URL) -> String {
        var nextURIIsPlaylist = false
        let lines = playlist.split(separator: "\n", omittingEmptySubsequences: false).map { line -> String in
            let line = line.hasSuffix("\r") ? String(line.dropLast()) : String(line)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { return line }

            if trimmed.hasPrefix("#") {
                if trimmed.hasPrefix("#EXT-X-STREAM-INF") {
                    nextURIIsPlaylist = true
                } else if trimmed.hasPrefix("#EXT-X-KEY") || trimmed.hasPrefix("#EXT-X-SESSION-KEY") {
                    return rewritingURIAttribute(in: line, baseURL: baseURL, scheme: keyScheme)
                } else if trimmed.hasPrefix("#EXT-X-MEDIA") || trimmed.hasPrefix("#EXT-X-I-FRAME-STREAM-INF") {
                    return rewritingURIAttribute(in: line, baseURL: baseURL, scheme: playlistScheme)
                } else if trimmed.hasPrefix("#EXT-X-MAP") {
                    return rewritingURIAttribute(in: line, baseURL: baseURL, scheme: nil)
                }
                return line
            }

            let scheme = nextURIIsPlaylist ? playlistScheme : nil
            nextURIIsPlaylist = false
            return absoluteURI(trimmed, baseURL: baseURL, scheme: scheme) ?? line
        }
        return lines.joined(separator: "\n")
    }

    private static let uriAttribute = try! NSRegularExpression(pattern: "URI=\"([^\"]*)\"")

    private static func rewritingURIAttribute(in line: String, baseURL: URL, scheme: String?) -> String {
        let nsLine = line as NSString
        guard let match = uriAttribute.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) else {
            return line
        }
        let uri = nsLine.substring(with: match.range(at: 1))
        guard let rewritten = absoluteURI(uri, baseURL: baseURL, scheme: scheme) else { return line }
        return nsLine.replacingCharacters(in: match.range(at: 1), with: rewritten)
    }

    /// Resolves `uri` against `baseURL`; when `scheme` is set, swaps https for it.
    /// Non-https URIs (e.g. `skd://`, `data:`) are left untouched by the scheme swap.
    private static func absoluteURI(_ uri: String, baseURL: URL, scheme: String?) -> String? {
        guard let resolved = URL(string: uri, relativeTo: baseURL)?.absoluteURL else { return nil }
        guard let scheme = scheme else { return resolved.absoluteString }
        return (replacingScheme(of: resolved, from: "https", to: scheme) ?? resolved).absoluteString
    }

    private static func replacingScheme(of url: URL, from: String, to: String) -> URL? {
        guard url.scheme?.lowercased() == from,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        components.scheme = to
        return components.url
    }

    private static func error(code: Int, _ message: String) -> NSError {
        NSError(domain: errorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
