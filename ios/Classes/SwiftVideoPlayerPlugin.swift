import AVFAudio
import AVFoundation
import Flutter
import UIKit

public class SwiftVideoPlayerPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate, VideoPlayerDelegate {
    private var flutterResult: FlutterResult?
    private static var channel: FlutterMethodChannel?
    public private(set) static var viewController: FlutterViewController?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
            viewController = rootViewController
        } else if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
                  let flutterController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController as? FlutterViewController {
            viewController = flutterController
        }
        channel = FlutterMethodChannel(name: "video_player", binaryMessenger: registrar.messenger())
        let instance = SwiftVideoPlayerPlugin()
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
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        flutterResult = result
        switch call.method {
        case "close":
            guard let presenter = SwiftVideoPlayerPlugin.viewController else {
                result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No FlutterViewController available to dismiss", details: nil))
                return
            }
            presenter.dismiss(animated: true)
            result(nil)
        case "playVideo":
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
            guard URL(string: playerConfiguration.url) != nil else {
                result(FlutterError(code: "INVALID_URL", message: "Invalid video URL", details: nil))
                return
            }
            let vc = VideoPlayerViewController()
            vc.delegate = self
            vc.modalPresentationStyle = .fullScreen
            vc.playerConfiguration = playerConfiguration
            vc.speedLabelText = playerConfiguration.speedText
            vc.qualityLabelText = playerConfiguration.qualityText
            vc.selectedQualityText = playerConfiguration.autoText
            presenter.present(vc, animated: true, completion: nil)
            return
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func getDuration(duration: [Int]) {
        flutterResult?(duration)
    }
}
