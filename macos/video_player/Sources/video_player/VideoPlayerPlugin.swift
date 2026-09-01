//
//  VideoPlayerPlugin.swift
//  video_player
//

import AppKit
import FlutterMacOS
import Foundation

public class VideoPlayerPlugin: NSObject, FlutterPlugin {
    private let registrar: FlutterPluginRegistrar
    private var activePlayerOverlay: VideoPlayerOverlayView?

    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "video_player", binaryMessenger: registrar.messenger)
        let instance = VideoPlayerPlugin(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)

        let viewFactory = VideoPlayerPlatformViewFactory(registrar: registrar)
        registrar.register(viewFactory, withId: "plugins.video/video_player_view")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "close":
            if let activePlayerOverlay = activePlayerOverlay {
                activePlayerOverlay.requestClose {
                    result(nil)
                }
            } else {
                result(nil)
            }

        case "playVideo":
            guard activePlayerOverlay == nil else {
                result(FlutterError(code: "PLAYER_ALREADY_ACTIVE", message: "A video player is already active", details: nil))
                return
            }

            guard let hostView = resolveHostView() else {
                result(FlutterError(code: "NO_HOST_VIEW", message: "No host view available to display player", details: nil))
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

            let overlayView = VideoPlayerOverlayView(configuration: resolvedConfiguration)
            activePlayerOverlay = overlayView

            overlayView.onPlaybackFinished = { [weak self] payload in
                result(payload)
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

        default:
            result(FlutterMethodNotImplemented)
        }
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
        guard !trimmedUrl.isEmpty, let remoteURL = URL(string: trimmedUrl) else {
            return .failure(VideoSourceResolutionFailure(code: "INVALID_URL", message: "Invalid video URL"))
        }

        resolvedConfiguration.url = remoteURL.absoluteString
        return .success(resolvedConfiguration)
    }
}
