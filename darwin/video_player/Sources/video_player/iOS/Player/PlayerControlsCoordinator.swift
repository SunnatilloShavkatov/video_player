#if os(iOS)
//
//  PlayerControlsCoordinator.swift
//  video_player
//
//  Created by Refactoring Phase 4 on 30/01/26.
//  Purpose: UI state synchronization (play/pause button, speed, quality, time labels)
//

import UIKit
import AVFoundation

/// Time slider drag phases, in seconds. Seeking itself belongs to PlayerController.
enum ScrubPhase {
    case began
    case moved(Double)
    case ended(Double)
}

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
    // While true (e.g. during a network stall) controls stay visible: no auto-hide
    private var autoHideSuspended = false
    // While the user drags the time slider, playback updates must not move it
    private var isScrubbing = false

    /// Time slider drag events; the owner turns them into seeks.
    var onScrub: ((ScrubPhase) -> Void)?

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
        bindTimeSlider()
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
        guard !isScrubbing else { return }
        setCurrentTimeLabel(seconds)
    }

    private func setCurrentTimeLabel(_ seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 1)
        currentTimeLabel?.text = VGPlayerUtils.getTimeString(from: time)
    }
    
    func updateDuration(seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 1)
        durationTimeLabel?.text = VGPlayerUtils.getTimeString(from: time)
    }
    
    // MARK: - Slider
    
    func updateSlider(currentSeconds: Double, durationSeconds: Double) {
        guard let slider = timeSlider, !isScrubbing else { return }

        // Only update if difference is significant (avoid jitter)
        let newValue = Float(currentSeconds)
        if abs(slider.value - newValue) > 0.1 {
            slider.maximumValue = Float(durationSeconds)
            slider.minimumValue = 0
            slider.value = newValue
        }
    }

    /// Reports drag phases to `onScrub`; while dragging, playback updates leave
    /// the thumb, the time label and the auto-hide timer alone.
    private func bindTimeSlider() {
        guard let slider = timeSlider else { return }
        slider.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.isScrubbing = true
            self.invalidateTimers()
            self.onScrub?(.began)
        }, for: .touchDown)
        slider.addAction(UIAction { [weak self, weak slider] _ in
            guard let self, let slider else { return }
            let seconds = Double(slider.value)
            if self.isScrubbing {
                self.setCurrentTimeLabel(seconds)
                self.onScrub?(.moved(seconds))
            } else {
                // Non-touch changes (e.g. VoiceOver increment) land immediately.
                self.onScrub?(.ended(seconds))
            }
        }, for: .valueChanged)
        slider.addAction(UIAction { [weak self, weak slider] _ in
            guard let self, let slider, self.isScrubbing else { return }
            self.isScrubbing = false
            self.onScrub?(.ended(Double(slider.value)))
            self.resetControlsTimer()
        }, for: [.touchUpInside, .touchUpOutside, .touchCancel])
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
            // The gesture recognizers are attached to PlayerView itself, so the
            // overlay can fade out without breaking tap-to-show behavior.
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
        guard !autoHideSuspended, !isScrubbing else {
            controlsTimer = nil
            return
        }
        controlsTimer = Timer.scheduledTimer(
            withTimeInterval: 5.0,
            repeats: false
        ) { [weak self] _ in
            self?.hideControls()
        }
    }

    /// Keep controls on screen indefinitely (used while playback is stalled)
    func suspendAutoHide() {
        autoHideSuspended = true
        controlsTimer?.invalidate()
        controlsTimer = nil
    }

    /// Restore normal auto-hide behavior after playback resumes
    func resumeAutoHide() {
        guard autoHideSuspended else { return }
        autoHideSuspended = false
        if controlsVisible {
            resetControlsTimer()
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

#endif
