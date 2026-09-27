//
//  EmbeddedPlayerObserver.swift
//  video_player
//
//  KVO, end-of-item notification and position ticks for the embedded player,
//  shared by iOS (VideoViewController) and macOS (VideoPlayerPlatformView).
//  Knows nothing about Flutter or UIKit/AppKit: the owner maps the callbacks
//  onto the per-view method channel. All time values are seconds.
//

import AVFoundation
import Foundation

final class EmbeddedPlayerObserver: NSObject {
    private static var playerItemContext = 0
    private static var playerContext = 0

    /// One of "idle", "ready", "error", "buffering", "paused", "playing", "ended".
    var onStatus: ((String) -> Void)?
    var onDuration: ((Double) -> Void)?
    var onPosition: ((Double) -> Void)?
    var onFinished: (() -> Void)?

    private let player: AVPlayer
    private var timeObserver: Any?
    private weak var currentPlayerItem: AVPlayerItem?

    // KVO callbacks can arrive off the main thread; the flags are read from both.
    private let stateQueue = DispatchQueue(label: "uz.plugin.video_player.macos_observer", qos: .userInitiated)
    private var _isObservingDuration = false
    private var _isObservingStatus = false
    private var _isObservingTimeControl = false
    private var _isInvalidated = false

    private var isObservingDuration: Bool {
        get { stateQueue.sync { _isObservingDuration } }
        set { stateQueue.sync { _isObservingDuration = newValue } }
    }
    private var isObservingStatus: Bool {
        get { stateQueue.sync { _isObservingStatus } }
        set { stateQueue.sync { _isObservingStatus = newValue } }
    }
    private var isObservingTimeControl: Bool {
        get { stateQueue.sync { _isObservingTimeControl } }
        set { stateQueue.sync { _isObservingTimeControl = newValue } }
    }
    private var isInvalidated: Bool { stateQueue.sync { _isInvalidated } }

    init(player: AVPlayer) {
        self.player = player
        super.init()
    }

    // MARK: - Public API

    /// True between `start()` and `stop()`/`invalidate()`.
    var isObserving: Bool { isObservingTimeControl }

    /// Observe the player's current item; call after `replaceCurrentItem`.
    func start() {
        setupPositionObserver()
        startObservingPlayerIfNeeded()
    }

    /// Remove every observer; `start()` may be called again for a new item.
    func stop() {
        stopObservingPlayerIfNeeded()
    }

    /// Final stop: no callbacks are delivered after this.
    func invalidate() {
        stateQueue.sync { _isInvalidated = true }
        stopObservingPlayerIfNeeded()
    }

    /// Duration in seconds; the seekable range end for live streams, 0 while unknown.
    func durationSeconds() -> Double {
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

    // MARK: - Observers

    private func startObservingPlayerIfNeeded() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.startObservingPlayerIfNeeded() }
            return
        }

        // Already observing: adding the item observers again would register them twice.
        guard !isInvalidated, !isObservingTimeControl, let item = player.currentItem else { return }

        player.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayer.timeControlStatus),
            options: [.new, .old],
            context: &EmbeddedPlayerObserver.playerContext
        )
        isObservingTimeControl = true

        item.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.duration),
            options: [.new, .initial],
            context: &EmbeddedPlayerObserver.playerItemContext
        )
        isObservingDuration = true

        item.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.status),
            options: .new,
            context: &EmbeddedPlayerObserver.playerItemContext
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
            player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), context: &EmbeddedPlayerObserver.playerContext)
            isObservingTimeControl = false
        }

        guard let item = currentPlayerItem else {
            isObservingDuration = false
            isObservingStatus = false
            return
        }

        if isObservingDuration {
            item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration), context: &EmbeddedPlayerObserver.playerItemContext)
            isObservingDuration = false
        }

        if isObservingStatus {
            item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &EmbeddedPlayerObserver.playerItemContext)
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
        if context == &EmbeddedPlayerObserver.playerItemContext {
            handlePlayerItemObservation(keyPath: keyPath, object: object)
        } else if context == &EmbeddedPlayerObserver.playerContext {
            handlePlayerObservation(keyPath: keyPath)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    private func handlePlayerItemObservation(keyPath: String?, object: Any?) {
        guard !isInvalidated, isObservingDuration || isObservingStatus else { return }

        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.handlePlayerItemObservation(keyPath: keyPath, object: object)
            }
            return
        }

        switch keyPath {
        case #keyPath(AVPlayerItem.duration):
            let duration = durationSeconds()
            if duration > 0 {
                onDuration?(duration)
            }
        case #keyPath(AVPlayerItem.status):
            guard let item = object as? AVPlayerItem else { return }
            switch item.status {
            case .readyToPlay:
                onStatus?("ready")
            case .failed:
                onStatus?("error")
            case .unknown:
                onStatus?("idle")
            @unknown default:
                break
            }
        default:
            break
        }
    }

    private func handlePlayerObservation(keyPath: String?) {
        guard !isInvalidated, isObservingTimeControl else { return }

        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.handlePlayerObservation(keyPath: keyPath)
            }
            return
        }

        guard keyPath == #keyPath(AVPlayer.timeControlStatus) else { return }
        switch player.timeControlStatus {
        case .waitingToPlayAtSpecifiedRate:
            onStatus?("buffering")
        case .paused:
            onStatus?("paused")
        case .playing:
            onStatus?("playing")
        @unknown default:
            break
        }
    }

    @objc private func playerDidFinishPlaying() {
        guard !isInvalidated else { return }
        onStatus?("ended")
        onFinished?()
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
            guard let self = self, !self.isInvalidated else { return }
            self.onPosition?(time.seconds)
        }
    }
}
