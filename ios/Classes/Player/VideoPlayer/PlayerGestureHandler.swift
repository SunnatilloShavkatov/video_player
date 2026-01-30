//
//  PlayerGestureHandler.swift
//  video_player
//
//  Created by Refactoring Phase 4 on 30/01/26.
//  Purpose: Gesture recognition and handling (tap, pan, pinch) with NO playback logic
//

import UIKit
import MediaPlayer

enum SwipeDirection {
    case vertical
    case horizontal
}

protocol PlayerGestureDelegate: AnyObject {
    func gestureHandlerDidTapToToggleControls(_ handler: PlayerGestureHandler)
    func gestureHandler(_ handler: PlayerGestureHandler, didTapInZone zone: TapZone)
    func gestureHandler(_ handler: PlayerGestureHandler, didPinchToScale scale: CGFloat)
    func gestureHandler(_ handler: PlayerGestureHandler, didSwipeVerticallyForBrightness delta: CGFloat)
    func gestureHandler(_ handler: PlayerGestureHandler, didSwipeVerticallyForVolume delta: CGFloat)
}

enum TapZone {
    case forward
    case backward
    case center
}

/// Handles all player gestures: tap, pan, pinch
/// This class has NO playback control logic
final class PlayerGestureHandler: NSObject {
    
    // MARK: - Properties
    
    weak var delegate: PlayerGestureDelegate?
    private weak var targetView: UIView?
    private weak var overlayView: UIView?
    
    private var swipeGesture: UIPanGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    private var tapHideGesture: UITapGestureRecognizer!
    private var pinchGesture: UIPinchGestureRecognizer!
    
    private var panDirection = SwipeDirection.vertical
    private var isVolume = false
    private var volumeViewSlider: UISlider!
    var enableGesture = true
    
    // MARK: - Initialization
    
    init(targetView: UIView, overlayView: UIView) {
        self.targetView = targetView
        self.overlayView = overlayView
        super.init()
        configureVolume()
        setupGestures()
    }
    
    // MARK: - Setup
    
    private func setupGestures() {
        guard let targetView = targetView else { return }
        
        // Pan gesture for volume/brightness
        swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipePan))
        swipeGesture.delegate = self
        targetView.addGestureRecognizer(swipeGesture)
        
        // Single tap for play/pause zone detection
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapControls))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        targetView.addGestureRecognizer(tapGesture)
        
        // Single tap for hiding controls
        
        // Pinch gesture for zoom
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        pinchGesture.delegate = self
        targetView.addGestureRecognizer(pinchGesture)
    }
    
    private func configureVolume() {
        let volumeView = MPVolumeView(frame: CGRect.zero)
        for subview in volumeView.subviews where subview is UISlider {
            volumeViewSlider = subview as? UISlider
            volumeViewSlider.isContinuous = false
            break
        }
    }
    
    // MARK: - Public API
    
    func setGesturesEnabled(_ enabled: Bool) {
        enableGesture = enabled
        swipeGesture?.isEnabled = enabled
        tapGesture?.isEnabled = enabled
        tapHideGesture?.isEnabled = enabled
        pinchGesture?.isEnabled = enabled
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handleSwipePan(_ gesture: UIPanGestureRecognizer) {
        guard enableGesture else { return }
        guard let targetView = targetView else { return }
        
        let translation = gesture.translation(in: targetView)
        let location = gesture.location(in: targetView)
        let velocity = gesture.velocity(in: targetView)
        
        switch gesture.state {
        case .began:
            let x = abs(velocity.x)
            let y = abs(velocity.y)
            
            if x > y {
                panDirection = .horizontal
            } else {
                panDirection = .vertical
                if location.x > targetView.bounds.width / 2 {
                    isVolume = true
                } else {
                    isVolume = false
                }
            }
            
        case .changed:
            if panDirection == .vertical {
                let delta = velocity.y / 10000
                if isVolume {
                    delegate?.gestureHandler(self, didSwipeVerticallyForVolume: -delta)
                } else {
                    delegate?.gestureHandler(self, didSwipeVerticallyForBrightness: -delta)
                }
            }
            
        case .ended:
            panDirection = .vertical
            
        default:
            break
        }
    }
    
    @objc private func handleTapControls(_ gesture: UITapGestureRecognizer) {
        guard enableGesture else { return }
        guard let overlayView = overlayView else { return }
        
        let location = gesture.location(in: overlayView)
        let overlayWidth = overlayView.bounds.width
        
        // Detect tap zone: forward (right), backward (left), center
        if location.x >= overlayWidth / 2 + 50 {
            delegate?.gestureHandler(self, didTapInZone: .forward)
        } else if location.x <= overlayWidth / 2 - 50 {
            delegate?.gestureHandler(self, didTapInZone: .backward)
        } else {
            delegate?.gestureHandlerDidTapToToggleControls(self)
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard enableGesture else { return }
        
        if gesture.state == .changed {
            delegate?.gestureHandler(self, didPinchToScale: gesture.scale)
        }
    }
    
    // MARK: - Volume Control
    
    func adjustVolume(by delta: Float) {
        guard let slider = volumeViewSlider else { return }
        let newValue = slider.value + delta
        slider.value = max(0.0, min(1.0, newValue))
    }
    
    // MARK: - Cleanup
    
    func removeGestures() {
        guard let targetView = targetView else { return }
        
        if let swipeGesture = swipeGesture {
            targetView.removeGestureRecognizer(swipeGesture)
        }
        if let tapGesture = tapGesture {
            targetView.removeGestureRecognizer(tapGesture)
        }
        if let pinchGesture = pinchGesture {
            targetView.removeGestureRecognizer(pinchGesture)
        }
    }
    
    deinit {
        removeGestures()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension PlayerGestureHandler: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Allow simultaneous recognition for better UX
        return true
    }
}
