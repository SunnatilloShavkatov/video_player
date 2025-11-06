import AVFoundation
import AVKit
import Flutter
import Foundation
import UIKit

class VideoPlayerView: NSObject, FlutterPlatformView {
    private var viewId: Int64
    private var videoView: UIView
    private var videoViewController: VideoViewController
    private var _methodChannel: FlutterMethodChannel
    
    func view() -> UIView {
        return videoView
    }
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: [String: Any]?,
        registrar: FlutterPluginRegistrar
    ) {
        self.viewId = viewId
        self.videoView = UIView(frame: frame)
        _methodChannel = FlutterMethodChannel(name: "plugins.video/video_player_view_\(viewId)", binaryMessenger: registrar.messenger())
        let url: String? = args?["url"] as? String
        let assets: String? = args?["assets"] as? String
        let sourceType: String? = args?["resizeMode"] as? String
        let gravity = videoGravity(s: sourceType ?? "")
        let viewController = VideoViewController(registrar: registrar, methodChannel: _methodChannel, assets: assets ?? "", url: url ?? "", gravity: gravity)
        self.videoViewController = viewController
        self.videoView.addSubview(videoViewController.view)
        
        // Add Auto Layout constraints to center and fill parent view
        videoViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoViewController.view.topAnchor.constraint(equalTo: videoView.topAnchor),
            videoViewController.view.leadingAnchor.constraint(equalTo: videoView.leadingAnchor),
            videoViewController.view.trailingAnchor.constraint(equalTo: videoView.trailingAnchor),
            videoViewController.view.bottomAnchor.constraint(equalTo: videoView.bottomAnchor)
        ])
        
        super.init()
        // Use weak self to prevent retain cycle
        _methodChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else {
                result(FlutterError(code: "DISPOSED", message: "VideoPlayerView has been disposed", details: nil))
                return
            }
            self.onMethodCall(call: call, result: result)
        }
    }
    
    deinit {
        // Properly cleanup video view controller and resources
        self._methodChannel.setMethodCallHandler(nil)
        self.videoViewController.view.removeFromSuperview()
        NotificationCenter.default.removeObserver(self)
    }
    
    func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        switch call.method {
        case "setUrl":
            setUrl(call: call, result: result)
        case "setAssets":
            setAssets(call: call, result: result)
        case "pause":
            setPause(call: call, result: result)
        case "play":
            setPlay(call: call, result: result)
        case "mute":
            setMute(call: call, result: result)
        case "unmute":
            setUnMute(call: call, result: result)
        case "getDuration":
            getDuration(result: result)
        case "seekTo":
            seekTo(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func setUrl(call: FlutterMethodCall, result: FlutterResult) {
        let arguments = call.arguments as? [String: Any]
        if let args = arguments {
            let videoPath: String? = args["url"] as? String
            let sourceType: String? = args["resizeMode"] as? String
            if let path = videoPath, !path.isEmpty {
                self.videoViewController.url = path
                self.videoViewController.playVideo(gravity: videoGravity(s: sourceType))
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_URL", message: "URL cannot be empty", details: nil))
            }
        } else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments are required", details: nil))
        }
    }
    
    func setAssets(call: FlutterMethodCall, result: FlutterResult) {
        let arguments = call.arguments as? [String: Any]
        if let args = arguments {
            // Check for 'assets' key first, fallback to 'url' for backward compatibility
            let videoPath: String? = args["assets"] as? String ?? args["url"] as? String
            let sourceType: String? = args["resizeMode"] as? String
            if let path = videoPath, !path.isEmpty {
                self.videoViewController.assets = path
                self.videoViewController.playVideo(gravity: videoGravity(s: sourceType))
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ASSET", message: "Asset path cannot be empty", details: nil))
            }
        } else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments are required", details: nil))
        }
    }
    
    func setPause(call: FlutterMethodCall, result: FlutterResult) {
        self.videoViewController.pause()
        result(nil)
    }
    
    func setPlay(call: FlutterMethodCall, result: FlutterResult) {
        self.videoViewController.play()
        result(nil)
    }
    
    func setMute(call: FlutterMethodCall, result: FlutterResult) {
        self.videoViewController.mute()
        result(nil)
    }
    
    func setUnMute(call: FlutterMethodCall, result: FlutterResult) {
        self.videoViewController.unMute()
        result(nil)
    }
    
    func getDuration(result: FlutterResult) {
        let duration = self.videoViewController.getDuration()
        result(duration) // Duration in seconds
    }
    
    func seekTo(call: FlutterMethodCall, result: FlutterResult) {
        let arguments = call.arguments as? [String: Any]
        if let args = arguments, let seconds = args["seconds"] as? Double {
            self.videoViewController.seekTo(seconds: seconds)
            result(nil)
        } else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "seconds parameter is required", details: nil))
        }
    }
}

func videoGravity(s: String?) -> AVLayerVideoGravity {
    switch s {
    case "fit":
        return .resizeAspect
    case "fill":
        return .resizeAspectFill
    case "zoom":
        return .resize
    default:
        return .resizeAspect
    }
}
