//
//  PlayerControlsCoordinator.swift
//  video_player
//
//  Created by Refactoring Phase 4 on 30/01/26.
//  Purpose: UI state synchronization (play/pause button, speed, quality, time labels)
//

import UIKit
import AVFoundation

/// Coordinates UI controls state with player state
/// This class updates UI elements but does NOT control playback
final class PlayerControlsCoordinator {
    
    // MARK: - UI References
    
    private weak var playButton: IconButton?
    private weak var timeSlider: UISlider?
    private weak var currentTimeLabel: UILabel?
    private weak var durationTimeLabel: UILabel?
    private weak var activityIndicator: UIActivityIndicatorView?
    
    private weak var topView: UIView?
    private weak var bottomView: UIView?
    private weak var overlayView: UIView?
    
    // Timer for auto-hide
    private var controlsTimer: Timer?

    // State
    private var controlsVisible = true
    
    // MARK: - Initialization
    
    init(
        playButton: IconButton?,
        timeSlider: UISlider?,
        currentTimeLabel: UILabel?,
        durationTimeLabel: UILabel?,
        activityIndicator: UIActivityIndicatorView?,
        topView: UIView?,
        bottomView: UIView?,
        overlayView: UIView?,
    ) {
        self.playButton = playButton
        self.timeSlider = timeSlider
        self.currentTimeLabel = currentTimeLabel
        self.durationTimeLabel = durationTimeLabel
        self.activityIndicator = activityIndicator
        self.topView = topView
        self.bottomView = bottomView
        self.overlayView = overlayView
    }
    
    // MARK: - Play/Pause Button
    
    func updatePlayButton(isPlaying: Bool) {
        if isPlaying {
            playButton?.setImage(Svg.pause, for: .normal)
        } else {
            playButton?.setImage(Svg.play, for: .normal)
        }
    }
    
    // MARK: - Time Display
    
    func updateCurrentTime(seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 1)
        currentTimeLabel?.text = VGPlayerUtils.getTimeString(from: time)
    }
    
    func updateDuration(seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 1)
        durationTimeLabel?.text = VGPlayerUtils.getTimeString(from: time)
    }
    
    // MARK: - Slider
    
    func updateSlider(currentSeconds: Double, durationSeconds: Double) {
        guard let slider = timeSlider else { return }
        
        // Only update if difference is significant (avoid jitter)
        let newValue = Float(currentSeconds)
        if abs(slider.value - newValue) > 0.1 {
            slider.maximumValue = Float(durationSeconds)
            slider.minimumValue = 0
            slider.value = newValue
        }
    }
    
    func setSliderValue(_ value: Float) {
        timeSlider?.value = value
    }
    
    // MARK: - Loading Indicator
    
    func showLoadingIndicator() {
        activityIndicator?.isHidden = false
        activityIndicator?.startAnimating()
    }
    
    func hideLoadingIndicator() {
        activityIndicator?.stopAnimating()
        activityIndicator?.isHidden = true
    }
    
    // MARK: - Controls Visibility
    
    func showControls() {
        guard !controlsVisible else { return }
        
        controlsVisible = true
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.topView?.alpha = 1.0
            self?.bottomView?.alpha = 1.0
            self?.overlayView?.alpha = 1.0
        }
        
        resetControlsTimer()
    }
    
    func hideControls() {
        guard controlsVisible else { return }
        
        controlsVisible = false
        controlsTimer?.invalidate()
        controlsTimer = nil
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.topView?.alpha = 0.0
            self?.bottomView?.alpha = 0.0
            self?.overlayView?.alpha = 0.0
        }
    }
    
    func toggleControls() {
        if controlsVisible {
            hideControls()
        } else {
            showControls()
        }
    }
    
    func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(
            withTimeInterval: 5.0,
            repeats: false
        ) { [weak self] _ in
            self?.hideControls()
        }
    }
    
    // MARK: - Cleanup
    
    func invalidateTimers() {
        controlsTimer?.invalidate()
        controlsTimer = nil
    }
    
    deinit {
        invalidateTimers()
    }
}
