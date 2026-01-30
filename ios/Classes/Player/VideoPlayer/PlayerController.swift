//
//  PlayerController.swift
//  video_player
//
//  Created by Refactoring Phase 4 on 30/01/26.
//  Purpose: AVPlayer lifecycle management, playback control (play/pause/seek/rate)
//

import AVFoundation
import UIKit

/// Manages AVPlayer lifecycle and playback control operations.
/// This class has NO UI dependencies and does NOT retain AVPlayer.
protocol PlayerControllerDelegate: AnyObject {
    func playerController(_ controller: PlayerController, didUpdatePosition seconds: Double)
    func playerController(_ controller: PlayerController, didUpdateDuration seconds: Double)
    func playerControllerDidFinishPlaying(_ controller: PlayerController)
    func playerController(_ controller: PlayerController, didChangeState state: LocalPlayerState)
}

final class PlayerController {
    
    // MARK: - Properties
    
    weak var delegate: PlayerControllerDelegate?
    private weak var player: AVPlayer?
    private weak var playerItem: AVPlayerItem?
    
    private(set) var playerState = LocalPlayerState.stopped
    private(set) var streamPosition: TimeInterval?
    private(set) var streamDuration: TimeInterval?
    private var playerRate: Float = 1.0
    
    // Pending operations
    private var pendingPlayPosition = TimeInterval()
    var pendingPlay: Bool = false
    var seeking: Bool = false
    
    // MARK: - Initialization
    
    init(player: AVPlayer) {
        self.player = player
    }
    
    // MARK: - Public API
    
    /// Updates the current player item reference
    func setPlayerItem(_ item: AVPlayerItem?) {
        self.playerItem = item
    }
    
    /// Start or resume playback
    func play() {
        guard let player = player else { return }
        
        playerState = .playing
        player.play()
        player.rate = playerRate
        
        delegate?.playerController(self, didChangeState: playerState)
    }
    
    /// Pause playback
    func pause() {
        guard let player = player else { return }
        
        playerState = .paused
        player.pause()
        
        delegate?.playerController(self, didChangeState: playerState)
    }
    
    /// Stop playback (pause without changing state to paused)
    func stop() {
        guard let player = player else { return }
        
        playerState = .stopped
        player.pause()
        
        delegate?.playerController(self, didChangeState: playerState)
    }
    
    /// Toggle between play and pause
    func togglePlayPause() {
        if playerState == .playing {
            pause()
        } else {
            play()
        }
    }
    
    /// Change playback speed
    func changeSpeed(rate: Float) {
        guard let player = player else { return }
        
        playerRate = rate
        if playerState == .playing {
            player.rate = rate
        }
    }
    
    /// Seek forward by specified seconds
    func seekForward(by seconds: Double) {
        guard let player = player,
              let duration = player.currentItem?.duration else { return }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime + seconds
        
        if newTime < (CMTimeGetSeconds(duration) - seconds) {
            let time = CMTimeMake(value: Int64(newTime * 1000), timescale: 1000)
            seek(to: time)
        }
    }
    
    /// Seek backward by specified seconds
    func seekBackward(by seconds: Double) {
        guard let player = player else { return }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = currentTime - seconds
        if newTime < 0 {
            newTime = 0
        }
        
        let time = CMTimeMake(value: Int64(newTime * 1000), timescale: 1000)
        seek(to: time)
    }
    
    /// Seek to specific position in seconds
    func seekToPosition(seconds: Double) {
        let time = CMTimeMake(value: Int64(seconds * 1000), timescale: 1000)
        seek(to: time)
    }
    
    /// Seek to specific CMTime
    private func seek(to time: CMTime) {
        guard let player = player else { return }
        
        seeking = true
        player.seek(to: time) { [weak self] finished in
            guard let self = self else { return }
            self.seeking = false
            if finished && self.pendingPlay {
                self.pendingPlay = false
                self.play()
            }
        }
    }
    
    /// Update position from time observer
    func updatePosition(_ seconds: Double) {
        streamPosition = seconds
        delegate?.playerController(self, didUpdatePosition: seconds)
    }
    
    /// Update duration when available
    func updateDuration(_ seconds: Double) {
        streamDuration = seconds
        delegate?.playerController(self, didUpdateDuration: seconds)
    }
    
    /// Notify that playback finished
    func notifyPlaybackFinished() {
        playerState = .stopped
        delegate?.playerControllerDidFinishPlaying(self)
    }
    
    /// Handle when player is ready to play
    func handlePlayerReady() {
        guard let player = player else { return }
        
        // Apply pending seek if needed
        if pendingPlayPosition > 0 {
            let time = CMTimeMake(
                value: Int64(pendingPlayPosition * 1000),
                timescale: 1000
            )
            player.seek(to: time) { [weak self] finished in
                guard let self = self, finished else { return }
                if self.pendingPlay {
                    self.play()
                }
            }
            pendingPlayPosition = 0
        } else if pendingPlay {
            play()
        }
    }
    
    /// Set pending play position (for initial seeking)
    func setPendingPlayPosition(_ position: TimeInterval) {
        pendingPlayPosition = position
    }
    
    /// Preroll the player at specified rate
    func preroll(atRate rate: Float) {
        guard let player = player else { return }
        player.preroll(atRate: rate) { [weak self] _ in
            self?.playerState = .starting
        }
    }
    
    /// Get current player time in seconds
    func getCurrentTime() -> Double {
        guard let player = player else { return 0 }
        return CMTimeGetSeconds(player.currentTime())
    }
    
    /// Get current item duration in seconds
    func getDuration() -> Double {
        guard let item = player?.currentItem else { return 0 }
        return CMTimeGetSeconds(item.duration)
    }
    
    /// Convert seconds to safe integer (avoiding overflow)
    func safeIntFromSeconds(_ seconds: Double) -> Int {
        guard seconds.isFinite, !seconds.isNaN else { return 0 }
        let milliseconds = seconds * 1000
        guard milliseconds >= Double(Int.min),
              milliseconds <= Double(Int.max) else { return 0 }
        return Int(milliseconds)
    }
}
