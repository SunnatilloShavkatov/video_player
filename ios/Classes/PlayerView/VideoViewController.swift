//
//  VideoViewController.swift
//  video_player
//
//  Created by Sunnatillo on 29/01/24.
//  FIXED: Memory leaks & KVO crashes resolved
//

import AVFoundation
import Foundation
import UIKit

class VideoViewController: UIViewController {

    // ✅ CRITICAL: Static contexts prevent Swift exclusivity violations
    private static var playerItemContext = 0
    private static var playerContext = 0

    private var registrar: FlutterPluginRegistrar?
    private var methodChannel: FlutterMethodChannel

    var assets: String = ""
    var url: String = ""
    var gravity: AVLayerVideoGravity

    // ✅ FIXED: Reusable player, not lazy (prevents multiple instances)
    private let player = AVPlayer()
    private var playerLayer: AVPlayerLayer?

    private lazy var videoView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    // Position observer
    private var timeObserver: Any?

    // ✅ FIXED: Thread-safe observer flags
    private let observerQueue = DispatchQueue(label: "com.video.observer", qos: .userInitiated)
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

    // ✅ FIXED: Weak reference to prevent retain cycle
    private weak var currentPlayerItem: AVPlayerItem?

    // ✅ FIXED: Disposal guard
    private var isDisposed = false
    private let disposalQueue = DispatchQueue(label: "com.video.disposal")

    init(registrar: FlutterPluginRegistrar? = nil,
         methodChannel: FlutterMethodChannel,
         assets: String,
         url: String,
         gravity: AVLayerVideoGravity) {
        self.registrar = registrar
        self.methodChannel = methodChannel
        self.assets = assets
        self.url = url
        self.gravity = gravity
        super.init(nibName: nil, bundle: nil)

        // Setup player early
        player.automaticallyWaitsToMinimizeStalling = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(videoView)

        videoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: view.topAnchor),
            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        playVideo(gravity: gravity)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { [weak self] _ in
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self?.updatePlayerLayerFrame()
            CATransaction.commit()
        }, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let layer = playerLayer, layer.superlayer != nil else { return }

        let newFrame = videoView.bounds
        guard !layer.frame.equalTo(newFrame) else { return }

        // ✅ FIXED: Disable animations for performance
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.frame = newFrame
        CATransaction.commit()
    }

    private func updatePlayerLayerFrame() {
        guard let layer = playerLayer, layer.superlayer != nil else { return }
        layer.frame = videoView.bounds
    }

    func playVideo(gravity: AVLayerVideoGravity) {
        guard !isDisposed else { return }

        stopObservingPlayerIfNeeded()

        player.pause()

        var videoURL: URL?
        if url.isEmpty {
            let key = self.registrar?.lookupKey(forAsset: assets)
            guard let path = Bundle.main.path(forResource: key, ofType: nil) else {
                sendError("Video not found for asset: \(assets)")
                return
            }
            videoURL = URL(fileURLWithPath: path)
        } else {
            guard let parsedUrl = URL(string: url) else {
                sendError("Invalid video URL: \(url)")
                return
            }
            videoURL = parsedUrl
        }

        guard let videoURL = videoURL else {
            sendError("Failed to create video URL")
            return
        }

        if playerLayer == nil {
            let layer = AVPlayerLayer(player: player)
            layer.frame = videoView.bounds
            layer.videoGravity = gravity
            videoView.layer.addSublayer(layer)
            playerLayer = layer
        } else {
            playerLayer?.videoGravity = gravity
        }

        let asset = AVURLAsset(url: videoURL)
        let playerItem = AVPlayerItem(asset: asset)

        player.replaceCurrentItem(with: playerItem)

        setupPositionObserver()
        startObservingPlayerIfNeeded()

        player.play()
    }

    // MARK: - Observer Management (Centralized)

    private func startObservingPlayerIfNeeded() {
        assert(Thread.isMainThread, "Observer setup must be on main thread")

        guard !isDisposed else { return }
        guard let item = player.currentItem else { return }

        if isObservingTimeControl {
            return
        }

        player.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayer.timeControlStatus),
            options: [.new, .old],
            context: &VideoViewController.playerContext
        )
        isObservingTimeControl = true

        item.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.duration),
            options: [.new, .initial],
            context: &VideoViewController.playerItemContext
        )
        isObservingDuration = true

        item.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.status),
            options: .new,
            context: &VideoViewController.playerItemContext
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
        assert(Thread.isMainThread, "Observer teardown must be on main thread")

        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }

        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)

        if isObservingTimeControl {
            do {
                player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), context: &VideoViewController.playerContext)
            } catch {
            }
            isObservingTimeControl = false
        }

        guard let item = currentPlayerItem else {
            isObservingDuration = false
            isObservingStatus = false
            return
        }

        if isObservingDuration {
            do {
                item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration), context: &VideoViewController.playerItemContext)
            } catch {
            }
            isObservingDuration = false
        }

        if isObservingStatus {
            do {
                item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &VideoViewController.playerItemContext)
            } catch {
            }
            isObservingStatus = false
        }

        currentPlayerItem = nil
    }

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {

        // ✅ CRITICAL: Check STATIC context to prevent exclusivity violations
        if context == &VideoViewController.playerItemContext {
            handlePlayerItemObservation(keyPath: keyPath, object: object, change: change)
        } else if context == &VideoViewController.playerContext {
            handlePlayerObservation(keyPath: keyPath, change: change)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    private func handlePlayerItemObservation(
        keyPath: String?,
        object: Any?,
        change: [NSKeyValueChangeKey : Any]?
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
        change: [NSKeyValueChangeKey : Any]?
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

    // MARK: - Playback Controls

    func pause() {
        player.pause()
    }

    func play() {
        guard !isDisposed else { return }
        player.play()
    }

    func mute() {
        player.isMuted = true
    }

    func unMute() {
        player.isMuted = false
    }

    func seekTo(seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setGravity(gravity: AVLayerVideoGravity) {
        playerLayer?.videoGravity = gravity
    }

    private func sendError(_ message: String) {
        debugPrint("[VideoViewController] Error: \(message)")
        methodChannel.invokeMethod("playerStatus", arguments: "error")
    }

    // MARK: - Lifecycle

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.pause()
        stopObservingPlayerIfNeeded()
    }

    deinit {
        cleanup()
    }

    private func cleanup() {
        disposalQueue.sync {
            guard !isDisposed else { return }
            isDisposed = true

            player.pause()

            // ✅ FIX: Avoid deadlock - if already on main, call directly; otherwise async
            if Thread.isMainThread {
                self.stopObservingPlayerIfNeeded()
            } else {
                DispatchQueue.main.async {
                    self.stopObservingPlayerIfNeeded()
                }
            }

            player.replaceCurrentItem(with: nil)

            if let layer = playerLayer, layer.superlayer != nil {
                layer.removeFromSuperlayer()
            }
            playerLayer = nil

            currentPlayerItem = nil
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
}
