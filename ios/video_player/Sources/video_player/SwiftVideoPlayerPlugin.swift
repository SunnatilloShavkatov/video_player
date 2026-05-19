import AVFAudio
import AVFoundation
import Flutter
import UIKit

private final class PlaybackSession {
    private let resolutionQueue = DispatchQueue(label: "uz.shs.video_player.playback_session")
    private let responder: FlutterResult
    private var isResolved = false

    init(responder: @escaping FlutterResult) {
        self.responder = responder
    }

    var resolved: Bool {
        resolutionQueue.sync { isResolved }
    }

    func resolve(with payload: [Int]) {
        let responderToCall = resolutionQueue.sync { () -> FlutterResult? in
            guard !isResolved else { return nil }
            isResolved = true
            return responder
        }

        guard let responderToCall else { return }
        if Thread.isMainThread {
            responderToCall(payload)
        } else {
            DispatchQueue.main.async {
                responderToCall(payload)
            }
        }
    }

    func resolve(error: FlutterError) {
        let responderToCall = resolutionQueue.sync { () -> FlutterResult? in
            guard !isResolved else { return nil }
            isResolved = true
            return responder
        }

        guard let responderToCall else { return }
        if Thread.isMainThread {
            responderToCall(error)
        } else {
            DispatchQueue.main.async {
                responderToCall(error)
            }
        }
    }

    func cancel() {
        let responderToCall = resolutionQueue.sync { () -> FlutterResult? in
            guard !isResolved else { return nil }
            isResolved = true
            return responder
        }

        guard let responderToCall else { return }
        if Thread.isMainThread {
            responderToCall(nil)
        } else {
            DispatchQueue.main.async {
                responderToCall(nil)
            }
        }
    }
}

struct VideoSourceResolutionFailure: Error {
    let code: String
    let message: String
}

public class SwiftVideoPlayerPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
    private static var channel: FlutterMethodChannel?
    public private(set) static var viewController: FlutterViewController?
    private var registrar: FlutterPluginRegistrar?
    private var activePlaybackSession: PlaybackSession?
    private weak var activePlayerViewController: VideoPlayerViewController?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftVideoPlayerPlugin()
        instance.registrar = registrar
        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
            viewController = rootViewController
        } else if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
                  let flutterController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController as? FlutterViewController {
            viewController = flutterController
        }
        channel = FlutterMethodChannel(name: "video_player", binaryMessenger: registrar.messenger())
        if let channel = channel {
            registrar.addMethodCallDelegate(instance, channel: channel)
        }
        registrar.addApplicationDelegate(instance)
        registrar.addSceneDelegate(instance)
        let videoViewFactory = VideoPlayerViewFactory(registrar: registrar)
        registrar.register(videoViewFactory, withId: "plugins.video/video_player_view")
    }
    
    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        updateViewController(from: scene)
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
        SwiftVideoPlayerPlugin.viewController = flutterController
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
        guard !trimmedUrl.isEmpty, let remoteURL = URL(string: trimmedUrl) else {
            return .failure(VideoSourceResolutionFailure(code: "INVALID_URL", message: "Invalid video URL"))
        }

        resolvedConfiguration.url = remoteURL.absoluteString
        return .success(resolvedConfiguration)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        cleanupOrphanedSessionIfNeeded()

        switch call.method {
        case "close":
            if let activePlayerViewController {
                activePlayerViewController.requestClose {
                    result(nil)
                }
            } else {
                result(nil)
            }
        case "playVideo":
            guard activePlayerViewController == nil else {
                result(FlutterError(code: "PLAYER_ALREADY_ACTIVE", message: "A video player is already active", details: nil))
                return
            }
            guard let presenter = SwiftVideoPlayerPlugin.viewController else {
                result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No FlutterViewController available to present video", details: nil))
                return
            }
            guard let args = call.arguments as? [String: String],
                  let playerConfigJsonString = args["playerConfigJsonString"],
                  let json = convertStringToDictionary(text: playerConfigJsonString),
                  let playerConfiguration = PlayerConfiguration.fromMap(map: json) else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid player configuration", details: nil))
                return
            }

            let resolvedConfiguration: PlayerConfiguration
            switch resolvePlaybackSource(for: playerConfiguration) {
            case .success(let configuration):
                resolvedConfiguration = configuration
            case .failure(let error):
                result(FlutterError(code: error.code, message: error.message, details: nil))
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
            presenter.present(vc, animated: true, completion: nil)
            return
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
