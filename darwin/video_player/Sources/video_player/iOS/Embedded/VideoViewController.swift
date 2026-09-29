#if os(iOS)
//
//  VideoViewController.swift
//  video_player
//
//  Created by Sunnatillo on 29/01/24.
//  FIXED: Memory leaks & KVO crashes resolved
//

import AVFoundation
import Flutter
import Foundation
import UIKit

class VideoViewController: UIViewController {

    private var registrar: FlutterPluginRegistrar?
    private var methodChannel: FlutterMethodChannel

    var assets: String = ""
    var url: String = ""
    /// Headers sent only with HLS AES-128 key requests (see HlsKeyResourceLoader).
    var keyRequestHeaders: [String: String] = [:]
    var gravity: AVLayerVideoGravity

    // ✅ FIXED: Reusable player, not lazy (prevents multiple instances)
    private let player = AVPlayer()
    private var playerLayer: AVPlayerLayer?
    // Retained here: AVAssetResourceLoader holds its delegate weakly.
    private var keyLoader: HlsKeyResourceLoader?

    private lazy var videoView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    // KVO, end-of-item and position ticks (Common/); events are forwarded in bindObserver()
    private lazy var observer = EmbeddedPlayerObserver(player: player)

    // ✅ FIXED: Disposal guard
    private var isDisposed = false
    private let disposalQueue = DispatchQueue(label: "com.video.disposal")
    // Set in viewWillDisappear when the video was playing; consumed in viewWillAppear.
    private var resumeOnAppear = false

    init(
        registrar: FlutterPluginRegistrar? = nil,
        methodChannel: FlutterMethodChannel,
        assets: String,
        url: String,
        keyRequestHeaders: [String: String] = [:],
        gravity: AVLayerVideoGravity
    ) {
        self.registrar = registrar
        self.methodChannel = methodChannel
        self.assets = assets
        self.url = url
        self.keyRequestHeaders = keyRequestHeaders
        self.gravity = gravity
        super.init(nibName: nil, bundle: nil)

        // Setup player early
        player.automaticallyWaitsToMinimizeStalling = true
        bindObserver()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(videoView)

        videoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: view.topAnchor),
            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        _ = playVideo(gravity: gravity)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(
            alongsideTransition: { [weak self] _ in
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self?.updatePlayerLayerFrame()
                CATransaction.commit()
            }, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let layer = playerLayer, layer.superlayer != nil else { return }

        let newFrame = videoView.bounds
        guard !layer.frame.equalTo(newFrame) else { return }

        // ✅ FIXED: Disable animations for performance
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.frame = newFrame
        CATransaction.commit()
    }

    private func updatePlayerLayerFrame() {
        guard let layer = playerLayer, layer.superlayer != nil else { return }
        layer.frame = videoView.bounds
    }

    @discardableResult
    func playVideo(gravity: AVLayerVideoGravity) -> FlutterError? {
        guard !isDisposed else {
            return FlutterError(code: "DISPOSED", message: "Video view controller is already disposed", details: nil)
        }

        observer.stop()

        player.pause()

        let videoURL: URL
        switch resolvePlaybackURL() {
        case .success(let resolvedURL):
            videoURL = resolvedURL
        case .failure(let error):
            sendError(error.message)
            return FlutterError(code: error.code, message: error.message, details: nil)
        }

        if playerLayer == nil {
            let layer = AVPlayerLayer(player: player)
            layer.frame = videoView.bounds
            layer.videoGravity = gravity
            videoView.layer.addSublayer(layer)
            playerLayer = layer
        } else {
            playerLayer?.videoGravity = gravity
        }

        let (asset, loader) = HlsKeyResourceLoader.makeAsset(url: videoURL, keyHeaders: keyRequestHeaders)
        keyLoader = loader
        let playerItem = AVPlayerItem(asset: asset)

        player.replaceCurrentItem(with: playerItem)

        observer.start()

        player.play()
        return nil
    }

    private func resolvePlaybackURL() -> Result<URL, VideoSourceResolutionFailure> {
        let trimmedAssetPath = assets.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedAssetPath.isEmpty {
            guard let registrar else {
                return .failure(VideoSourceResolutionFailure(code: "NO_REGISTRAR", message: "Flutter registrar unavailable for asset lookup"))
            }

            let lookupKey = registrar.lookupKey(forAsset: trimmedAssetPath)
            guard let assetFilePath = Bundle.main.path(forResource: lookupKey, ofType: nil) else {
                return .failure(VideoSourceResolutionFailure(code: "ASSET_NOT_FOUND", message: "Asset not found: \(trimmedAssetPath)"))
            }

            return .success(URL(fileURLWithPath: assetFilePath))
        }

        let trimmedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUrl.isEmpty, let remoteURL = URL(string: trimmedUrl), remoteURL.isSecureRemote else {
            return .failure(VideoSourceResolutionFailure(code: "INVALID_URL", message: "Invalid video URL: \(url)"))
        }

        return .success(remoteURL)
    }

    // MARK: - Observer Events

    private func bindObserver() {
        observer.onStatus = { [weak self] status in self?.send("playerStatus", status) }
        observer.onDuration = { [weak self] seconds in self?.send("durationReady", seconds) }
        observer.onPosition = { [weak self] seconds in self?.send("positionUpdate", seconds) }
        observer.onFinished = { [weak self] in self?.send("finished", nil) }
    }

    private func send(_ method: String, _ arguments: Any?) {
        guard !isDisposed else { return }
        methodChannel.invokeMethod(method, arguments: arguments)
    }

    func getDuration() -> Double {
        observer.durationSeconds()
    }

    // MARK: - Playback Controls

    func pause() {
        // A pause from Dart while hidden wins over resuming on reappear.
        resumeOnAppear = false
        player.pause()
    }

    func play() {
        guard !isDisposed else { return }
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

    func setGravity(gravity: AVLayerVideoGravity) {
        playerLayer?.videoGravity = gravity
    }

    private func sendError(_ message: String) {
        debugPrint("[VideoViewController] Error: \(message)")
        methodChannel.invokeMethod("playerStatus", arguments: "error")
    }

    // MARK: - Lifecycle

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // rate is non-zero while playing or buffering to play
        resumeOnAppear = player.rate != 0
        player.pause()
        observer.stop()
    }

    /// Undoes viewWillDisappear (e.g. a modal full-screen player was dismissed over
    /// the Flutter screen): events restart, and playback resumes if it was running.
    /// The first appearance is a no-op: playVideo already started the observer.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !isDisposed, player.currentItem != nil else { return }
        if !observer.isObserving {
            observer.start()
        }
        if resumeOnAppear {
            resumeOnAppear = false
            player.play()
        }
    }

    deinit {
        cleanup()
    }

    private func cleanup() {
        let shouldCleanup = disposalQueue.sync { () -> Bool in
            guard !isDisposed else { return false }
            isDisposed = true
            return true
        }

        guard shouldCleanup else { return }

        let teardown = {
            self.player.pause()
            self.observer.invalidate()
            self.player.replaceCurrentItem(with: nil)

            if let layer = self.playerLayer, layer.superlayer != nil {
                layer.removeFromSuperlayer()
            }
            self.playerLayer = nil
        }

        if Thread.isMainThread {
            teardown()
        } else {
            DispatchQueue.main.sync(execute: teardown)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
}

#endif
