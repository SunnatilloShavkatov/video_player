#if os(iOS)
//
//  PlaybackRecoveryManager.swift
//  video_player
//
//  Purpose: Recover a stalled AVPlayer — after a network stall, when connectivity
//  returns, and when the app comes back to the foreground. No UI dependencies.
//

import AVFoundation
import UIKit

final class PlaybackRecoveryManager {

    // MARK: - Properties

    private weak var player: AVPlayer?
    private var stallRecoveryTimer: Timer?
    private let stallRecoveryDelay: TimeInterval = 8.0

    /// Called when seek-based recovery fails; the owner rebuilds the item at the given position.
    var onReloadRequired: ((_ positionSeconds: Double) -> Void)?
    /// Whether playback was intended to be running (used to resume after foregrounding).
    var shouldResumePlayback: (() -> Bool)?

    // MARK: - Initialization

    init(player: AVPlayer) {
        self.player = player
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NetworkMonitor.shared.startMonitoring()
        NetworkMonitor.shared.onNetworkStatusChange = { [weak self] isConnected in
            guard let self, isConnected,
                  self.player?.timeControlStatus == .waitingToPlayAtSpecifiedRate else { return }
            debugPrint("🌐 Network restored — triggering stall recovery")
            self.scheduleStallRecovery()
        }
    }

    // MARK: - Public API

    /// Schedule a single stall recovery attempt; no-op while one is already pending.
    func scheduleStallRecovery() {
        guard !(stallRecoveryTimer?.isValid ?? false) else { return }
        stallRecoveryTimer = Timer.scheduledTimer(withTimeInterval: stallRecoveryDelay, repeats: false) { [weak self] _ in
            self?.recoverFromStall()
        }
    }

    func cancelStallRecovery() {
        stallRecoveryTimer?.invalidate()
        stallRecoveryTimer = nil
    }

    // MARK: - Recovery

    /// Seek to the current position and re-play; fall back to reloading the item.
    private func recoverFromStall() {
        stallRecoveryTimer = nil
        guard let player, player.timeControlStatus == .waitingToPlayAtSpecifiedRate else { return }

        debugPrint("🔄 Stall recovery: attempting seek-and-play")
        let currentTime = player.currentTime()
        player.seek(to: currentTime, toleranceBefore: .zero, toleranceAfter: CMTime(seconds: 1, preferredTimescale: 1)) { [weak self] finished in
            guard let self else { return }
            if finished {
                self.player?.play()
            } else {
                debugPrint("⚠️ Stall recovery: seek failed, attempting item reload")
                self.onReloadRequired?(CMTimeGetSeconds(currentTime))
            }
        }
    }

    /// After returning from background (or long inactivity), nudge a stuck player
    /// or resume one that was playing before.
    @objc private func appDidBecomeActive() {
        guard let player, let item = player.currentItem else { return }
        if player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
            player.seek(to: player.currentTime(), toleranceBefore: .zero, toleranceAfter: .zero) { [weak player] _ in
                player?.play()
            }
        } else if item.status == .readyToPlay, player.timeControlStatus == .paused,
                  shouldResumePlayback?() == true {
            player.play()
        }
    }

    deinit {
        stallRecoveryTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

#endif
