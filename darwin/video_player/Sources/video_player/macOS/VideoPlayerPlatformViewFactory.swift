//
//  VideoPlayerPlatformViewFactory.swift
//  video_player
//

#if os(macOS)
import AppKit
import FlutterMacOS
import Foundation

class VideoPlayerPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
    private let registrar: FlutterPluginRegistrar

    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        super.init()
    }

    func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
        return VideoPlayerPlatformView(
            viewId: viewId,
            arguments: args as? [String: Any],
            registrar: registrar
        )
    }

    func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
#endif
