//
//  PlayerObserverManager.swift
//  video_player
//
//  Created by Refactoring Phase 4 on 30/01/26.
//  Purpose: KVO and NotificationCenter observer management with safe lifecycle
//

import AVFoundation
import UIKit

/// Delegate protocol for observer callbacks
protocol PlayerObserverDelegate: AnyObject {
    func observerManager(_ manager: PlayerObserverManager, didUpdateDuration duration: TimeInterval)
    func observerManager(_ manager: PlayerObserverManager, didUpdateStatus status: AVPlayerItem.Status)
    func observerManager(_ manager: PlayerObserverManager, didChangeTimeControlStatus status: AVPlayer.TimeControlStatus)
    func observerManager(_ manager: PlayerObserverManager, didUpdatePosition position: TimeInterval, duration: TimeInterval)
    func observerManagerDidFinishPlaying(_ manager: PlayerObserverManager)
}

/// Manages all KVO and NotificationCenter observers for AVPlayer/AVPlayerItem.
/// Ensures safe attach/detach following the rules from MEMORY_LEAK_FIXES.md
final class PlayerObserverManager: NSObject {
    
    // MARK: - KVO Contexts (thread-safe unique identifiers)
    
    private static var playerItemStatusContext = 0
    private static var playerItemDurationContext = 0
    private static var playerTimeControlStatusContext = 0
    
    // MARK: - Properties
    
    weak var delegate: PlayerObserverDelegate?
    private weak var player: AVPlayer?
    private weak var observedPlayerItem: AVPlayerItem?
    
    private var mediaTimeObserver: Any?
    private var observingMediaPlayer: Bool = false
    private var isDisposed: Bool = false
    
    // MARK: - Initialization
    
    init(player: AVPlayer) {
        self.player = player
        super.init()
    }
    
    // MARK: - Public API
    
    /// Add all observers (KVO + NotificationCenter + time observer)
    /// MUST be called on main thread
    func addObservers(for playerItem: AVPlayerItem) {
        assert(Thread.isMainThread, "addObservers must be called on main thread")
        
        // Prevent duplicate observers
        guard !observingMediaPlayer else {
            debugPrint("⚠️ Observers already attached, skipping")
            return
        }
        
        guard let player = player, !isDisposed else { return }
        
        // Store reference to the item we're observing
        observedPlayerItem = playerItem
        
        // 1. Add NotificationCenter observer for item end notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        // 2. Add KVO observers with proper contexts (CRITICAL for safe removal)
        playerItem.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.duration),
            options: [.new, .initial],
            context: &PlayerObserverManager.playerItemDurationContext
        )
        
        playerItem.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.status),
            options: .new,
            context: &PlayerObserverManager.playerItemStatusContext
        )
        
        player.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayer.timeControlStatus),
            options: [.old, .new],
            context: &PlayerObserverManager.playerTimeControlStatusContext
        )
        
        // 3. Add periodic time observer
        addTimeObserver()
        
        // Mark that we're now observing - only after all observers are successfully added
        observingMediaPlayer = true
    }
    
    /// Remove all observers safely
    /// MUST be called on main thread
    func removeObservers() {
        // Ensure we're on the main thread for observer removal
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.removeObservers()
            }
            return
        }
        
        guard let player = player else { return }
        
        // Remove time observer first
        if let timeObserver = mediaTimeObserver {
            player.removeTimeObserver(timeObserver)
            mediaTimeObserver = nil
        }
        
        // Remove KVO observers - use stored reference to avoid issues
        if observingMediaPlayer {
            // CRITICAL: Pause player first to stop all notifications
            let wasPlaying = player.rate > 0
            if wasPlaying {
                player.pause()
                player.rate = 0.0
            }
            
            // Store strong reference to prevent deallocation during removal
            let observedItem = observedPlayerItem
            
            // CRITICAL: Clear flag BEFORE removing observers
            observingMediaPlayer = false
            observedPlayerItem = nil
            
            // Remove observers from the stored item reference
            if let item = observedItem {
                // Remove notification observer first
                NotificationCenter.default.removeObserver(
                    self,
                    name: .AVPlayerItemDidPlayToEndTime,
                    object: item
                )
                
                // Then remove KVO observers with proper contexts
                item.removeObserver(
                    self,
                    forKeyPath: #keyPath(AVPlayerItem.duration),
                    context: &PlayerObserverManager.playerItemDurationContext
                )
                
                item.removeObserver(
                    self,
                    forKeyPath: #keyPath(AVPlayerItem.status),
                    context: &PlayerObserverManager.playerItemStatusContext
                )
            }
            
            // Always remove player observer if we were observing
            player.removeObserver(
                self,
                forKeyPath: #keyPath(AVPlayer.timeControlStatus),
                context: &PlayerObserverManager.playerTimeControlStatusContext
            )
        }
    }
    
    /// Mark as disposed (prevents any further operations)
    func dispose() {
        isDisposed = true
        removeObservers()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private Methods
    
    private func addTimeObserver() {
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        // ✅ OPTIMIZED: Use background queue for time observer processing
        // This prevents blocking the main thread during playback time calculations
        let timeObserverQueue = DispatchQueue(
            label: "video.player.time.observer",
            qos: .userInitiated  // High priority but non-UI work
        )
        
        mediaTimeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: timeObserverQueue  // ✅ Background queue
        ) { [weak self] time in
            // BACKGROUND THREAD: Do all calculations here
            guard let self = self,
                  !self.isDisposed,
                  let currentItem = self.player?.currentItem else { return }
            
            let duration = currentItem.duration
            let durationSeconds = CMTimeGetSeconds(duration)
            
            // Validate duration
            guard duration.isValid,
                  !CMTIME_IS_INDEFINITE(duration),
                  durationSeconds.isFinite,
                  !durationSeconds.isNaN,
                  durationSeconds > 0 else {
                // Try to get duration from seekable ranges for live streams
                if let seekableRange = currentItem.seekableTimeRanges.last?.timeRangeValue {
                    let endTime = CMTimeAdd(seekableRange.start, seekableRange.duration)
                    let seekableSeconds = CMTimeGetSeconds(endTime)
                    if seekableSeconds.isFinite && !seekableSeconds.isNaN && seekableSeconds > 0 {
                        // ✅ MAIN THREAD: Dispatch delegate call (UI update)
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self, !self.isDisposed else { return }
                            self.delegate?.observerManager(
                                self,
                                didUpdatePosition: 0,
                                duration: seekableSeconds
                            )
                        }
                    }
                }
                return
            }
            
            let currentTime = currentItem.currentTime()
            let currentSeconds = CMTimeGetSeconds(currentTime)
            
            guard currentSeconds.isFinite && !currentSeconds.isNaN else { return }
            
            // ✅ MAIN THREAD: Dispatch delegate call (UI update)
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !self.isDisposed else { return }
                self.delegate?.observerManager(
                    self,
                    didUpdatePosition: currentSeconds,
                    duration: durationSeconds
                )
            }
        }
    }
    
    // MARK: - KVO Observation
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        // CRITICAL: Check if we're still observing (disposal guard)
        guard observingMediaPlayer, !isDisposed else {
            return
        }
        
        // Duration change
        if context == &PlayerObserverManager.playerItemDurationContext {
            if let duration = change?[.newKey] as? CMTime {
                let seconds = CMTimeGetSeconds(duration)
                if seconds.isFinite && !seconds.isNaN && seconds > 0 {
                    delegate?.observerManager(self, didUpdateDuration: seconds)
                }
            }
        }
        // Status change
        else if context == &PlayerObserverManager.playerItemStatusContext {
            if let statusNumber = change?[.newKey] as? NSNumber {
                let status = AVPlayerItem.Status(rawValue: statusNumber.intValue) ?? .unknown
                delegate?.observerManager(self, didUpdateStatus: status)
            }
        }
        // Time control status change
        else if context == &PlayerObserverManager.playerTimeControlStatusContext {
            if let statusNumber = change?[.newKey] as? NSNumber {
                let status = AVPlayer.TimeControlStatus(rawValue: statusNumber.intValue) ?? .paused
                delegate?.observerManager(self, didChangeTimeControlStatus: status)
            }
        }
        else {
            // Not our observation - pass to super
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: - Notification Handlers
    
    @objc private func playerDidFinishPlaying(_ notification: Notification) {
        guard !isDisposed else { return }
        delegate?.observerManagerDidFinishPlaying(self)
    }
    
    // MARK: - Deinitialization
    
    deinit {
        // Safety: ensure all observers are removed
        dispose()
    }
}
