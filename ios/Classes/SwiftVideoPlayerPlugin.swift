import AVFAudio
import AVFoundation
import Flutter
import UIKit

public class SwiftVideoPlayerPlugin: NSObject, FlutterPlugin, VideoPlayerDelegate {
    private var flutterResult: FlutterResult?
    private static var channel: FlutterMethodChannel?
    public static var viewController = FlutterViewController()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        guard let rootViewController = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController else {
            return
        }
        viewController = rootViewController
        channel = FlutterMethodChannel(name: "video_player", binaryMessenger: registrar.messenger())
        let instance = SwiftVideoPlayerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel!)
        let videoViewFactory = VideoPlayerViewFactory(registrar: registrar)
        registrar.register(videoViewFactory, withId: "plugins.video/video_player_view")
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        flutterResult = result
        switch call.method {
        case "close":
            SwiftVideoPlayerPlugin.viewController.dismiss(animated: true)
            result(nil)
        case "playVideo":
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
            SwiftVideoPlayerPlugin.viewController.present(vc, animated: true, completion: nil)
            return
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func getDuration(duration: [Int]) {
        flutterResult?(duration)
    }
}
