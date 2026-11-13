//
//  VideoPlayerPlugin.swift
//  video_player
//

#if os(iOS)
import AVFAudio
import AVFoundation
import Flutter
import UIKit

private final class PlaybackSession {
    private let resolutionQueue = DispatchQueue(label: "uz.plugin.video_player.playback_session")
    private let responder: PlayBlock
    private var isResolved = false

    init(responder: @escaping PlayBlock) {
        self.responder = responder
    }

    var resolved: Bool {
        resolutionQueue.sync { isResolved }
    }

    func resolve(with payload: [Int]) {
        complete(payload.first ?? 0, payload.dropFirst().first ?? 0, nil, nil)
    }

    func resolve(code: String, message: String) {
        complete(-1, -1, code, message)
    }

    func cancel() {
        complete(-1, -1, nil, nil)
    }

    /// Claims the single resolution, then delivers it to the responder on the main thread.
    private func complete(_ position: Int, _ duration: Int, _ code: String?, _ message: String?) {
        let responderToCall = resolutionQueue.sync { () -> PlayBlock? in
            guard !isResolved else { return nil }
            isResolved = true
            return responder
        }

        guard let responderToCall else { return }
        if Thread.isMainThread {
            responderToCall(position, duration, code, message)
        } else {
            DispatchQueue.main.async {
                responderToCall(position, duration, code, message)
            }
        }
    }
}

struct VideoSourceResolutionFailure: Error {
    let code: String
    let message: String
}

public class VideoPlayerPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate, VideoPlayerHost {
    public private(set) static var viewController: FlutterViewController?
    private var registrar: FlutterPluginRegistrar?
    private var activePlaybackSession: PlaybackSession?
    private weak var activePlayerViewController: VideoPlayerViewController?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = VideoPlayerPlugin()
        instance.registrar = registrar
        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
            viewController = rootViewController
        } else if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
                  let flutterController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController as? FlutterViewController {
            viewController = flutterController
        }
        VideoPlayerApi.host = instance
        registrar.addApplicationDelegate(instance)
        registrar.addSceneDelegate(instance)
        let videoViewFactory = VideoPlayerViewFactory(registrar: registrar)
        registrar.register(videoViewFactory, withId: "plugins.video/video_player_view")
    }

    // Signature must match FlutterSceneLifeCycleDelegate exactly (Bool return, optional
    // options) or Flutter never calls it. Returns false: we observe, not handle, the connection.
    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions?) -> Bool {
        updateViewController(from: scene)
        return false
    }

    public func sceneDidBecomeActive(_ scene: UIScene) {
        updateViewController(from: scene)
    }

    public func sceneWillEnterForeground(_ scene: UIScene) {
        updateViewController(from: scene)
    }

    private func updateViewController(from scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene,
              let flutterController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController as? FlutterViewController else {
            return
        }
        VideoPlayerPlugin.viewController = flutterController
    }

    private func cleanupOrphanedSessionIfNeeded() {
        if activePlayerViewController == nil, let session = activePlaybackSession {
            if session.resolved {
                activePlaybackSession = nil
            } else {
                session.cancel()
                activePlaybackSession = nil
            }
        }
    }

    private func bindPlaybackLifecycle(
        to viewController: VideoPlayerViewController,
        session: PlaybackSession
    ) {
        viewController.onPlaybackFinished = { [weak self, weak viewController] payload in
            session.resolve(with: payload)
            if self?.activePlayerViewController === viewController {
                self?.activePlaybackSession = nil
            }
        }

        viewController.onPlaybackFailed = { [weak self, weak viewController] code, message in
            session.resolve(code: code, message: message)
            if self?.activePlayerViewController === viewController {
                self?.activePlaybackSession = nil
            }
        }

        viewController.onDidDismiss = { [weak self, weak viewController] in
            if self?.activePlayerViewController === viewController {
                self?.activePlayerViewController = nil
            }
            if self?.activePlaybackSession?.resolved == true {
                self?.activePlaybackSession = nil
            }
        }
    }

    private func resolvePlaybackSource(
        for configuration: PlayerConfiguration
    ) -> Result<PlayerConfiguration, VideoSourceResolutionFailure> {
        var resolvedConfiguration = configuration

        if configuration.playVideoFromAsset {
            guard let assetPath = configuration.assetPath?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !assetPath.isEmpty else {
                return .failure(VideoSourceResolutionFailure(code: "INVALID_ASSET", message: "Asset path is missing"))
            }

            guard let registrar else {
                return .failure(VideoSourceResolutionFailure(code: "NO_REGISTRAR", message: "Flutter registrar unavailable for asset lookup"))
            }

            let lookupKey = registrar.lookupKey(forAsset: assetPath)
            guard let assetFilePath = Bundle.main.path(forResource: lookupKey, ofType: nil) else {
                return .failure(VideoSourceResolutionFailure(code: "ASSET_NOT_FOUND", message: "Asset not found: \(assetPath)"))
            }

            resolvedConfiguration.url = URL(fileURLWithPath: assetFilePath).absoluteString
            return .success(resolvedConfiguration)
        }

        let trimmedUrl = configuration.url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUrl.isEmpty, let remoteURL = URL(string: trimmedUrl), remoteURL.isSecureRemote else {
            return .failure(VideoSourceResolutionFailure(code: "INVALID_URL", message: "Invalid video URL: only HTTPS is allowed"))
        }

        resolvedConfiguration.url = remoteURL.absoluteString
        return .success(resolvedConfiguration)
    }

    func closePlayer(completion: @escaping () -> Void) {
        cleanupOrphanedSessionIfNeeded()
        if let activePlayerViewController {
            activePlayerViewController.requestClose {
                completion()
            }
        } else {
            completion()
        }
    }

    func playVideo(configJson playerConfigJsonString: String, completion result: @escaping PlayBlock) {
        cleanupOrphanedSessionIfNeeded()
        guard activePlayerViewController == nil else {
            result(-1, -1, "PLAYER_ALREADY_ACTIVE", "A video player is already active")
            return
        }
        guard let presenter = VideoPlayerPlugin.viewController else {
            result(-1, -1, "NO_VIEW_CONTROLLER", "No FlutterViewController available to present video")
            return
        }
        guard let json = convertStringToDictionary(text: playerConfigJsonString),
              let playerConfiguration = PlayerConfiguration.fromMap(map: json) else {
            result(-1, -1, "INVALID_ARGS", "Invalid player configuration")
            return
        }

        let resolvedConfiguration: PlayerConfiguration
        switch resolvePlaybackSource(for: playerConfiguration) {
        case .success(let configuration):
            resolvedConfiguration = configuration
        case .failure(let error):
            result(-1, -1, error.code, error.message)
            return
        }

        let vc = VideoPlayerViewController()
        vc.modalPresentationStyle = .fullScreen
        vc.playerConfiguration = resolvedConfiguration
        vc.speedLabelText = resolvedConfiguration.speedText
        vc.qualityLabelText = resolvedConfiguration.qualityText
        vc.selectedQualityText = resolvedConfiguration.autoText
        let session = PlaybackSession(responder: result)
        activePlaybackSession = session
        activePlayerViewController = vc
        bindPlaybackLifecycle(to: vc, session: session)
        if let orientation = presenter.view.window?.windowScene?.interfaceOrientation {
            vc.pinOrientationForPresentation(to: orientation)
        }
        presenter.present(vc, animated: true, completion: nil)
    }
}

#elseif os(macOS)
import AppKit
import FlutterMacOS
import Foundation

struct VideoSourceResolutionFailure: Error {
    let code: String
    let message: String
}

public class VideoPlayerPlugin: NSObject, FlutterPlugin, VideoPlayerHost {
    private let registrar: FlutterPluginRegistrar
    private var activePlayerOverlay: VideoPlayerOverlayView?

    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = VideoPlayerPlugin(registrar: registrar)
        VideoPlayerApi.host = instance

        let viewFactory = VideoPlayerPlatformViewFactory(registrar: registrar)
        registrar.register(viewFactory, withId: "plugins.video/video_player_view")
    }

    func closePlayer(completion: @escaping () -> Void) {
        if let activePlayerOverlay = activePlayerOverlay {
            activePlayerOverlay.requestClose {
                completion()
            }
        } else {
            completion()
        }
    }

    func playVideo(configJson playerConfigJsonString: String, completion result: @escaping PlayBlock) {
        guard activePlayerOverlay == nil else {
            result(-1, -1, "PLAYER_ALREADY_ACTIVE", "A video player is already active")
            return
        }

        guard let hostView = resolveHostView() else {
            result(-1, -1, "NO_HOST_VIEW", "No host view available to display player")
            return
        }

        guard let json = convertStringToDictionary(text: playerConfigJsonString),
              let playerConfiguration = PlayerConfiguration.fromMap(map: json) else {
            result(-1, -1, "INVALID_ARGS", "Invalid player configuration")
            return
        }

        let resolvedConfiguration: PlayerConfiguration
        switch resolvePlaybackSource(for: playerConfiguration) {
        case .success(let configuration):
            resolvedConfiguration = configuration
        case .failure(let error):
            result(-1, -1, error.code, error.message)
            return
        }

        let overlayView = VideoPlayerOverlayView(configuration: resolvedConfiguration)
        activePlayerOverlay = overlayView

        overlayView.onPlaybackFinished = { [weak self] payload in
            result(payload.first ?? 0, payload.dropFirst().first ?? 0, nil, nil)
            self?.activePlayerOverlay = nil
        }

        overlayView.onPlaybackFailed = { [weak self] code, message in
            result(-1, -1, code, message)
            self?.activePlayerOverlay = nil
        }

        overlayView.onDidDismiss = { [weak self] in
            self?.activePlayerOverlay = nil
        }

        overlayView.translatesAutoresizingMaskIntoConstraints = false
        hostView.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: hostView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: hostView.bottomAnchor),
        ])

        overlayView.alphaValue = 0.0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            overlayView.animator().alphaValue = 1.0
        }

        hostView.window?.makeFirstResponder(overlayView)

        // Playback starts last: an immediate failure has to find the callbacks in place.
        overlayView.start()
    }

    private func resolveHostView() -> NSView? {
        if let view = registrar.viewController?.view {
            return view
        }
        if let view = registrar.view {
            return view
        }
        return NSApp.keyWindow?.contentView ?? NSApp.mainWindow?.contentView
    }

    private func resolvePlaybackSource(
        for configuration: PlayerConfiguration
    ) -> Result<PlayerConfiguration, VideoSourceResolutionFailure> {
        var resolvedConfiguration = configuration

        if configuration.playVideoFromAsset {
            guard let assetPath = configuration.assetPath?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !assetPath.isEmpty else {
                return .failure(VideoSourceResolutionFailure(code: "INVALID_ASSET", message: "Asset path is missing"))
            }

            let lookupKey = registrar.lookupKey(forAsset: assetPath)
            guard let assetFilePath = Bundle.main.path(forResource: lookupKey, ofType: nil) else {
                return .failure(VideoSourceResolutionFailure(code: "ASSET_NOT_FOUND", message: "Asset not found: \(assetPath)"))
            }

            resolvedConfiguration.url = URL(fileURLWithPath: assetFilePath).absoluteString
            return .success(resolvedConfiguration)
        }

        let trimmedUrl = configuration.url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUrl.isEmpty, let remoteURL = URL(string: trimmedUrl), remoteURL.isSecureRemote else {
            return .failure(VideoSourceResolutionFailure(code: "INVALID_URL", message: "Invalid video URL: only HTTPS is allowed"))
        }

        resolvedConfiguration.url = remoteURL.absoluteString
        return .success(resolvedConfiguration)
    }
}
#endif
