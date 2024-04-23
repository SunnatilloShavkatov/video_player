//
//  VideoViewController.swift
//  udevs_video_player
//
//  Created by Udevs on 29/01/24.
//

import Foundation
import AVFoundation

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
    lazy private var videoView : UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    init(registrar: FlutterPluginRegistrar? = nil, methodChannel: FlutterMethodChannel, assets: String, url:String, gravity: AVLayerVideoGravity) {
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
        playVideo(gravity: gravity)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    func playVideo(gravity : AVLayerVideoGravity) {
        var videoURL : URL
        if url.isEmpty {
            let key = self.registrar?.lookupKey(forAsset: assets)
            guard let path = Bundle.main.path(forResource: key, ofType: nil) else {
                debugPrint("video not found")
                return
            }
            videoURL = URL(fileURLWithPath: path)
        } else {
            videoURL = URL(string: url)!
        }
        player.automaticallyWaitsToMinimizeStalling = true
        player.replaceCurrentItem(with: AVPlayerItem(asset: AVURLAsset(url: videoURL)))
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.view.bounds
        playerLayer.videoGravity = gravity
        self.videoView.layer.addSublayer(playerLayer)
        player.play()
    }
    
    func pause(){
        player.pause()
    }
    
    func setGravity(gravity : AVLayerVideoGravity){
        playerLayer.videoGravity = gravity
    }
    
    func play(){
        player.play()
    }
    
    func mute(){
        player.isMuted = true
    }
    
    func unMute(){
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
