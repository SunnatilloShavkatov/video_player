//
//  VideoViewController.swift
//  video_player
//
//  Created by Sunnatillo on 29/01/24.
//

import AVFoundation
import Foundation

class VideoViewController: UIViewController {
    
    private var registrar: FlutterPluginRegistrar?
    private var methodChannel: FlutterMethodChannel
    
    //
    var assets: String = ""
    var url: String = ""
    var gravity: AVLayerVideoGravity
    
    //
    lazy private var player = AVPlayer()
    lazy private var playerLayer = AVPlayerLayer()
    lazy private var videoView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    // Position observer for streaming current time
    private var timeObserver: Any?
    
    // Track if observers are added to prevent duplicate removals
    private var isObservingDuration = false
    private var isObservingStatus = false
    private var observedPlayerItem: AVPlayerItem?
    
    init(registrar: FlutterPluginRegistrar? = nil, methodChannel: FlutterMethodChannel, assets: String, url: String, gravity: AVLayerVideoGravity) {
        self.registrar = registrar
        self.methodChannel = methodChannel
        self.assets = assets
        self.url = url
        self.gravity = gravity
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(videoView)
        
        // Add Auto Layout constraints for videoView
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
            // Update playerLayer frame when orientation changes
            self?.updatePlayerLayerFrame()
        }, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update playerLayer frame when view size changes
        updatePlayerLayerFrame()
    }
    
    private func updatePlayerLayerFrame() {
        // Update playerLayer frame to match current view bounds
        if playerLayer.superlayer != nil {
            playerLayer.frame = videoView.bounds
        }
    }
    
    func playVideo(gravity: AVLayerVideoGravity) {
        var videoURL: URL
        if url.isEmpty {
            let key = self.registrar?.lookupKey(forAsset: assets)
            guard let path = Bundle.main.path(forResource: key, ofType: nil) else {
                debugPrint("video not found")
                return
            }
            videoURL = URL(fileURLWithPath: path)
        } else {
            guard let url = URL(string: url) else {
                debugPrint("Invalid video URL")
                return
            }
            videoURL = url
        }
        
        // Remove old playerLayer before creating new one to prevent memory leaks
        if playerLayer.superlayer != nil {
            playerLayer.removeFromSuperlayer()
        }
        
        // Safely remove old item observers if any
        removePlayerItemObservers()
        
        player.automaticallyWaitsToMinimizeStalling = true
        let playerItem = AVPlayerItem(asset: AVURLAsset(url: videoURL))
        
        // Add observer for duration to notify when available
        playerItem.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
        playerItem.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        
        // Track that we're observing this item
        isObservingDuration = true
        isObservingStatus = true
        observedPlayerItem = playerItem
        
        player.replaceCurrentItem(with: playerItem)
        
        // Create new playerLayer
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoView.bounds
        playerLayer.videoGravity = gravity
        self.videoView.layer.addSublayer(playerLayer)
        
        // Setup position observer for streaming
        setupPositionObserver()
        
        player.play()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "duration" {
            let duration = getDuration()
            if duration > 0 {
                // Send duration ready event when available
                methodChannel.invokeMethod("durationReady", arguments: duration)
            }
        } else if keyPath == "status" {
            if let playerItem = object as? AVPlayerItem,
               playerItem.status == .readyToPlay {
                // When item is ready, check and send duration
                let duration = getDuration()
                if duration > 0 {
                    methodChannel.invokeMethod("durationReady", arguments: duration)
                }
            }
        }
    }
    
    private func setupPositionObserver() {
        // Remove existing observer if any
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        // Add periodic time observer to stream position updates (1 second interval)
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] time in
            guard let self = self else { return }
            let positionSeconds = time.seconds
            // Send position update via method channel (in seconds)
            self.methodChannel.invokeMethod("positionUpdate", arguments: positionSeconds)
        }
    }
    
    func getDuration() -> Double {
        guard let currentItem = player.currentItem else {
            return 0.0
        }
        let duration = currentItem.duration
        
        // Check if duration is valid and not indefinite
        guard duration.isValid && !duration.isIndefinite else {
            // Try to get duration from seekable time ranges as fallback
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
        
        // Check if duration is finite and valid
        guard durationSeconds.isFinite && !durationSeconds.isNaN && durationSeconds > 0 else {
            return 0.0
        }
        
        return durationSeconds // Return in seconds
    }
    
    func pause() {
        player.pause()
    }
    
    func setGravity(gravity: AVLayerVideoGravity) {
        playerLayer.videoGravity = gravity
    }
    
    func play() {
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
    
    deinit {
        // Remove time observer
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        // Safely remove item observers
        removePlayerItemObservers()
        
        playerLayer.removeFromSuperlayer()
        player.pause()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove time observer
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        // Safely remove item observers
        removePlayerItemObservers()
        
        if playerLayer.superlayer != nil {
            playerLayer.removeFromSuperlayer()
        }
        player.pause()
        NotificationCenter.default.removeObserver(self)
        methodChannel.invokeMethod("finished", arguments: "finished")
    }
    
    // Helper method to safely remove player item observers
    private func removePlayerItemObservers() {
        // Only remove if we're actually observing and item exists
        guard (isObservingDuration || isObservingStatus), let item = observedPlayerItem else {
            return
        }
        
        // Remove observers only if we tracked them as added
        // This prevents crashes from removing observers that were never added or already removed
        if isObservingDuration {
            item.removeObserver(self, forKeyPath: "duration")
            isObservingDuration = false
        }
        if isObservingStatus {
            item.removeObserver(self, forKeyPath: "status")
            isObservingStatus = false
        }
        
        // Clear the reference after removing observers
        observedPlayerItem = nil
    }
}
