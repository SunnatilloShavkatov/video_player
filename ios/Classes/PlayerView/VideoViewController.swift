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
        
        player.automaticallyWaitsToMinimizeStalling = true
        player.replaceCurrentItem(with: AVPlayerItem(asset: AVURLAsset(url: videoURL)))
        
        // Create new playerLayer
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoView.bounds
        playerLayer.videoGravity = gravity
        self.videoView.layer.addSublayer(playerLayer)
        player.play()
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
    
    deinit {
        playerLayer.removeFromSuperlayer()
        player.pause()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        playerLayer.removeFromSuperlayer()
        player.pause()
        NotificationCenter.default.removeObserver(self)
        methodChannel.invokeMethod("finished", arguments: "finished")
    }
}
