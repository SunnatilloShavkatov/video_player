import Foundation
import AVKit
import AVFoundation
import Flutter
import UIKit

class VideoPlayerView: NSObject, FlutterPlatformView {
    private var viewId: Int64
    private var videoView : UIView
    private var videoViewController: VideoViewController
    private var _methodChannel: FlutterMethodChannel
    
    func view() -> UIView {
        return videoView
    }
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: [String:Any]?,
        registrar: FlutterPluginRegistrar
    ) {
        self.viewId = viewId
        self.videoView = UIView(frame: frame)
        _methodChannel = FlutterMethodChannel(name: "plugins.udevs/video_player_view_\(viewId)", binaryMessenger: registrar.messenger())
        let url: String? = args?["url"] as? String
        let assets: String? = args?["assets"] as? String
        let sourceType: String? = args?["resizeMode"] as? String
        let gravity = videoGravity(s: sourceType ?? "")
        let viewController = VideoViewController(registrar: registrar, methodChannel: _methodChannel, assets: assets ?? "", url: url ?? "", gravity: gravity)
        self.videoViewController = viewController
        self.videoView.addSubview(videoViewController.view)
        super.init()
        _methodChannel.setMethodCallHandler(onMethodCall)
    }
    
    deinit {
        self.videoViewController.dismiss(animated: true)
        NotificationCenter.default.removeObserver(self)
        self._methodChannel.setMethodCallHandler(nil)
    }


    func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        switch(call.method){
        case "setUrl":
            setUrl(call:call, result:result)
        case "setAssets":
            setAssets(call:call, result:result)
        case "pause":
            setPause(call: call, result: result)
        case "play":
            setPlay(call: call, result: result)
        case "mute":
            setMute(call: call, result: result)
        case "un-mute":
            setUnMute(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func setUrl(call: FlutterMethodCall, result: FlutterResult){
        let arguments = call.arguments as? [String:Any]
        if let args = arguments {
            let videoPath: String? = args["url"] as? String
            let sourceType: String? = args["resizeMode"] as? String
            self.videoViewController.url = videoPath ?? ""
            self.videoViewController.playVideo(gravity: videoGravity(s: sourceType))
            result(nil)
        }
    }
    
    func setAssets(call: FlutterMethodCall, result: FlutterResult){
        let arguments = call.arguments as? [String:Any]
        if let args = arguments {
            let videoPath: String? = args["url"] as? String
            let sourceType: String? = args["resizeMode"] as? String
            self.videoViewController.assets = videoPath ?? ""
            self.videoViewController.playVideo(gravity: videoGravity(s: sourceType))
            result(nil)
        }
    }
    
    func setPause(call: FlutterMethodCall, result: FlutterResult){
        self.videoViewController.pause()
    }
    
    func setPlay(call: FlutterMethodCall, result: FlutterResult){
        self.videoViewController.play()
    }
    
    func setMute(call: FlutterMethodCall, result: FlutterResult){
        self.videoViewController.mute()
    }
    
    func setUnMute(call: FlutterMethodCall, result: FlutterResult){
        self.videoViewController.unMute()
    }
}

func videoGravity(s:String?) -> AVLayerVideoGravity {
    switch(s){
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
