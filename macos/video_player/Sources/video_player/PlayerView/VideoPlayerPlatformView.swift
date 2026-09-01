//
//  VideoPlayerPlatformView.swift
//  video_player
//

import AVFoundation
import AppKit
import FlutterMacOS
import Foundation

class VideoPlayerPlatformView: NSView {
    private static var playerItemContext = 0
    private static var playerContext = 0

    private let viewId: Int64
    private let registrar: FlutterPluginRegistrar
    private let methodChannel: FlutterMethodChannel

    private let player = AVPlayer()
    private var playerLayer: AVPlayerLayer?

    var url: String = ""
    var assets: String = ""
    var gravity: AVLayerVideoGravity = .resizeAspect

    private var timeObserver: Any?

    private let observerQueue = DispatchQueue(label: "uz.shs.video_player.macos_observer", qos: .userInitiated)
    private var _isObservingDuration = false
    private var _isObservingStatus = false
    private var _isObservingTimeControl = false

    private var isObservingDuration: Bool {
        get { observerQueue.sync { _isObservingDuration } }
        set { observerQueue.sync { _isObservingDuration = newValue } }
    }
    private var isObservingStatus: Bool {
        get { observerQueue.sync { _isObservingStatus } }
        set { observerQueue.sync { _isObservingStatus = newValue } }
    }
    private var isObservingTimeControl: Bool {
        get { observerQueue.sync { _isObservingTimeControl } }
        set { observerQueue.sync { _isObservingTimeControl = newValue } }
    }

    private weak var currentPlayerItem: AVPlayerItem?
    private var _isDisposed = false
    private let disposalQueue = DispatchQueue(label: "uz.shs.video_player.macos_disposal")

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
        self.gravity = videoGravity(s: resizeMode)
        self.playerLayer?.videoGravity = self.gravity

        player.automaticallyWaitsToMinimizeStalling = true

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

        stopObservingPlayerIfNeeded()
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

        let asset = AVURLAsset(url: videoURL)
        let playerItem = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: playerItem)

        setupPositionObserver()
        startObservingPlayerIfNeeded()

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
        guard !trimmedUrl.isEmpty, let remoteURL = URL(string: trimmedUrl) else {
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
        guard let currentItem = player.currentItem else { return 0.0 }
        let duration = currentItem.duration

        guard duration.isValid && !duration.isIndefinite else {
            if let seekableRange = currentItem.seekableTimeRanges.last?.timeRangeValue {
                let endTime = CMTimeAdd(seekableRange.start, seekableRange.duration)
                let seconds = CMTimeGetSeconds(endTime)
                if seconds.isFinite && !seconds.isNaN && seconds > 0 {
                    return seconds
                }
            }
            return 0.0
        }

        let durationSeconds = duration.seconds
        guard durationSeconds.isFinite && !durationSeconds.isNaN && durationSeconds > 0 else {
            return 0.0
        }

        return durationSeconds
    }

    private func sendError(_ message: String) {
        methodChannel.invokeMethod("playerStatus", arguments: "error")
    }

    // MARK: - Observers

    private func startObservingPlayerIfNeeded() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.startObservingPlayerIfNeeded() }
            return
        }

        guard !isDisposed, let item = player.currentItem else { return }

        if !isObservingTimeControl {
            player.addObserver(
                self,
                forKeyPath: #keyPath(AVPlayer.timeControlStatus),
                options: [.new, .old],
                context: &VideoPlayerPlatformView.playerContext
            )
            isObservingTimeControl = true
        }

        item.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.duration),
            options: [.new, .initial],
            context: &VideoPlayerPlatformView.playerItemContext
        )
        isObservingDuration = true

        item.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.status),
            options: .new,
            context: &VideoPlayerPlatformView.playerItemContext
        )
        isObservingStatus = true

        currentPlayerItem = item

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
    }

    private func stopObservingPlayerIfNeeded() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.stopObservingPlayerIfNeeded() }
            return
        }

        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }

        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)

        if isObservingTimeControl {
            player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), context: &VideoPlayerPlatformView.playerContext)
            isObservingTimeControl = false
        }

        guard let item = currentPlayerItem else {
            isObservingDuration = false
            isObservingStatus = false
            return
        }

        if isObservingDuration {
            item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration), context: &VideoPlayerPlatformView.playerItemContext)
            isObservingDuration = false
        }

        if isObservingStatus {
            item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &VideoPlayerPlatformView.playerItemContext)
            isObservingStatus = false
        }

        currentPlayerItem = nil
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if context == &VideoPlayerPlatformView.playerItemContext {
            handlePlayerItemObservation(keyPath: keyPath, object: object, change: change)
        } else if context == &VideoPlayerPlatformView.playerContext {
            handlePlayerObservation(keyPath: keyPath, change: change)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    private func handlePlayerItemObservation(
        keyPath: String?,
        object: Any?,
        change: [NSKeyValueChangeKey: Any]?
    ) {
        guard !isDisposed, isObservingDuration || isObservingStatus else { return }

        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.handlePlayerItemObservation(keyPath: keyPath, object: object, change: change)
            }
            return
        }

        guard let keyPath = keyPath else { return }

        switch keyPath {
        case #keyPath(AVPlayerItem.duration):
            let duration = getDuration()
            if duration > 0 {
                methodChannel.invokeMethod("durationReady", arguments: duration)
            }
        case #keyPath(AVPlayerItem.status):
            if let item = object as? AVPlayerItem {
                switch item.status {
                case .readyToPlay:
                    methodChannel.invokeMethod("playerStatus", arguments: "ready")
                case .failed:
                    methodChannel.invokeMethod("playerStatus", arguments: "error")
                case .unknown:
                    methodChannel.invokeMethod("playerStatus", arguments: "idle")
                @unknown default:
                    break
                }
            }
        default:
            break
        }
    }

    private func handlePlayerObservation(
        keyPath: String?,
        change: [NSKeyValueChangeKey: Any]?
    ) {
        guard !isDisposed, isObservingTimeControl else { return }

        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.handlePlayerObservation(keyPath: keyPath, change: change)
            }
            return
        }

        guard let keyPath = keyPath else { return }

        switch keyPath {
        case #keyPath(AVPlayer.timeControlStatus):
            switch player.timeControlStatus {
            case .waitingToPlayAtSpecifiedRate:
                methodChannel.invokeMethod("playerStatus", arguments: "buffering")
            case .paused:
                methodChannel.invokeMethod("playerStatus", arguments: "paused")
            case .playing:
                methodChannel.invokeMethod("playerStatus", arguments: "playing")
            @unknown default:
                break
            }
        default:
            break
        }
    }

    @objc private func playerDidFinishPlaying() {
        guard !isDisposed else { return }
        methodChannel.invokeMethod("playerStatus", arguments: "ended")
        methodChannel.invokeMethod("finished", arguments: nil)
    }

    private func setupPositionObserver() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }

        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: DispatchQueue.main
        ) { [weak self] time in
            guard let self = self, !self.isDisposed else { return }
            let positionSeconds = time.seconds
            self.methodChannel.invokeMethod("positionUpdate", arguments: positionSeconds)
        }
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
        stopObservingPlayerIfNeeded()
        player.replaceCurrentItem(with: nil)
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        currentPlayerItem = nil
    }
}
