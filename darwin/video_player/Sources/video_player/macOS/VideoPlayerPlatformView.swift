//
//  VideoPlayerPlatformView.swift
//  video_player
//

#if os(macOS)
import AVFoundation
import AppKit
import FlutterMacOS
import Foundation

class VideoPlayerPlatformView: NSView {
    private let viewId: Int64
    private let registrar: FlutterPluginRegistrar
    private let methodChannel: FlutterMethodChannel

    private let player = AVPlayer()
    private var playerLayer: AVPlayerLayer?

    var url: String = ""
    var assets: String = ""
    /// Headers sent only with HLS AES-128 key requests (see HlsKeyResourceLoader).
    var keyRequestHeaders: [String: String] = [:]
    var gravity: AVLayerVideoGravity = .resizeAspect
    // Retained here: AVAssetResourceLoader holds its delegate weakly.
    private var keyLoader: HlsKeyResourceLoader?

    // KVO, end-of-item and position ticks; events are forwarded in bindObserver()
    private lazy var observer = EmbeddedPlayerObserver(player: player)

    private var _isDisposed = false
    private let disposalQueue = DispatchQueue(label: "uz.plugin.video_player.macos_disposal")

    private var isDisposed: Bool {
        disposalQueue.sync { _isDisposed }
    }

    init(
        viewId: Int64,
        arguments args: [String: Any]?,
        registrar: FlutterPluginRegistrar
    ) {
        self.viewId = viewId
        self.registrar = registrar
        self.methodChannel = FlutterMethodChannel(
            name: "plugins.video/video_player_view_\(viewId)",
            binaryMessenger: registrar.messenger
        )

        super.init(frame: .zero)

        self.wantsLayer = true
        self.layer = CALayer()
        self.layer?.backgroundColor = NSColor.black.cgColor

        let layer = AVPlayerLayer(player: player)
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        self.layer?.addSublayer(layer)
        self.playerLayer = layer

        let urlArg = args?["url"] as? String ?? ""
        let assetsArg = args?["assets"] as? String ?? ""
        let resizeMode = args?["resizeMode"] as? String
        self.url = urlArg
        self.assets = assetsArg
        self.keyRequestHeaders = args?["keyRequestHeaders"] as? [String: String] ?? [:]
        self.gravity = videoGravity(s: resizeMode)
        self.playerLayer?.videoGravity = self.gravity

        player.automaticallyWaitsToMinimizeStalling = true
        bindObserver()

        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self, !self.isDisposed else {
                result(FlutterError(code: "DISPOSED", message: "VideoPlayerView has been disposed", details: nil))
                return
            }
            self.onMethodCall(call: call, result: result)
        }

        if !url.isEmpty || !assets.isEmpty {
            _ = playVideo(gravity: self.gravity)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer?.frame = bounds
        CATransaction.commit()
    }

    private func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        switch call.method {
        case "setUrl":
            setUrl(call: call, result: result)
        case "setAssets":
            setAssets(call: call, result: result)
        case "pause":
            pause()
            result(nil)
        case "play":
            play()
            result(nil)
        case "mute":
            mute()
            result(nil)
        case "unmute":
            unmute()
            result(nil)
        case "getDuration":
            let duration = getDuration()
            result(duration)
        case "seekTo":
            seekTo(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func setUrl(call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let videoPath = args["url"] as? String,
              !videoPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            result(FlutterError(code: "INVALID_URL", message: "URL cannot be empty", details: nil))
            return
        }

        let sourceType = args["resizeMode"] as? String
        self.assets = ""
        self.url = videoPath
        self.keyRequestHeaders = args["keyRequestHeaders"] as? [String: String] ?? [:]
        if let error = playVideo(gravity: videoGravity(s: sourceType)) {
            result(error)
        } else {
            result(nil)
        }
    }

    private func setAssets(call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let videoPath = (args["assets"] as? String ?? args["url"] as? String),
              !videoPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            result(FlutterError(code: "INVALID_ASSET", message: "Asset path cannot be empty", details: nil))
            return
        }

        let sourceType = args["resizeMode"] as? String
        self.url = ""
        self.assets = videoPath
        self.keyRequestHeaders = [:]
        if let error = playVideo(gravity: videoGravity(s: sourceType)) {
            result(error)
        } else {
            result(nil)
        }
    }

    private func playVideo(gravity: AVLayerVideoGravity) -> FlutterError? {
        guard !isDisposed else {
            return FlutterError(code: "DISPOSED", message: "Video view is disposed", details: nil)
        }

        observer.stop()
        player.pause()

        let videoURL: URL
        switch resolvePlaybackURL() {
        case .success(let resolvedURL):
            videoURL = resolvedURL
        case .failure(let error):
            sendError(error.message)
            return FlutterError(code: error.code, message: error.message, details: nil)
        }

        self.gravity = gravity
        playerLayer?.videoGravity = gravity

        let (asset, loader) = HlsKeyResourceLoader.makeAsset(url: videoURL, keyHeaders: keyRequestHeaders)
        keyLoader = loader
        let playerItem = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: playerItem)

        observer.start()

        player.play()
        return nil
    }

    private func resolvePlaybackURL() -> Result<URL, VideoSourceResolutionFailure> {
        let trimmedAssetPath = assets.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedAssetPath.isEmpty {
            let lookupKey = registrar.lookupKey(forAsset: trimmedAssetPath)
            guard let assetFilePath = Bundle.main.path(forResource: lookupKey, ofType: nil) else {
                return .failure(VideoSourceResolutionFailure(code: "ASSET_NOT_FOUND", message: "Asset not found: \(trimmedAssetPath)"))
            }
            return .success(URL(fileURLWithPath: assetFilePath))
        }

        let trimmedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUrl.isEmpty, let remoteURL = URL(string: trimmedUrl), remoteURL.isSecureRemote else {
            return .failure(VideoSourceResolutionFailure(code: "INVALID_URL", message: "Invalid video URL: \(url)"))
        }

        return .success(remoteURL)
    }

    // MARK: - Playback Controls

    func play() {
        guard !isDisposed else { return }
        player.play()
    }

    func pause() {
        player.pause()
    }

    func mute() {
        player.isMuted = true
    }

    func unmute() {
        player.isMuted = false
    }

    func seekTo(call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let seconds = args["seconds"] as? Double else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "seconds parameter is required", details: nil))
            return
        }

        let targetTime = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        result(nil)
    }

    func getDuration() -> Double {
        observer.durationSeconds()
    }

    private func sendError(_ message: String) {
        methodChannel.invokeMethod("playerStatus", arguments: "error")
    }

    // MARK: - Observer Events

    private func bindObserver() {
        observer.onStatus = { [weak self] status in self?.send("playerStatus", status) }
        observer.onDuration = { [weak self] seconds in self?.send("durationReady", seconds) }
        observer.onPosition = { [weak self] seconds in self?.send("positionUpdate", seconds) }
        observer.onFinished = { [weak self] in self?.send("finished", nil) }
    }

    private func send(_ method: String, _ arguments: Any?) {
        guard !isDisposed else { return }
        methodChannel.invokeMethod(method, arguments: arguments)
    }

    // MARK: - Deinitialization

    deinit {
        cleanup()
    }

    private func cleanup() {
        let shouldCleanup = disposalQueue.sync { () -> Bool in
            guard !_isDisposed else { return false }
            _isDisposed = true
            return true
        }

        guard shouldCleanup else { return }

        methodChannel.setMethodCallHandler(nil)
        player.pause()
        observer.invalidate()
        player.replaceCurrentItem(with: nil)
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
}
#endif
