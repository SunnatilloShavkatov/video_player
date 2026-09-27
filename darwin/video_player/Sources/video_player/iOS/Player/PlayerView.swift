#if os(iOS)
//
//  PlayerView.swift
//  video_player
//
//  Full-screen player view. Orchestrates focused components and owns no
//  layout or subtitle/recovery logic itself:
//  - PlayerOverlayView          controls hierarchy + layout
//  - PlayerController           play/pause/seek/rate
//  - PlayerObserverManager      KVO + notifications
//  - PlayerGestureHandler       tap/pan/pinch
//  - PlayerControlsCoordinator  controls state + auto-hide
//  - PlaybackRecoveryManager    stall / network / foreground recovery
//  - SubtitleController         sidecar WebVTT subtitles
//

import AVFoundation
import AVKit
import UIKit

protocol PlayerViewDelegate: NSObjectProtocol {
    func close(duration: [Int])
    func settingsPressed()
    func changeOrientation()
    func togglePictureInPictureMode()
    func share()
}

enum LocalPlayerState: Int {
    case stopped
    case starting
    case playing
    case paused
}

class PlayerView: UIView {

    // MARK: - Components

    private var playerController: PlayerController!
    private var observerManager: PlayerObserverManager!
    private var gestureHandler: PlayerGestureHandler!
    private var controlsCoordinator: PlayerControlsCoordinator!
    private lazy var recoveryManager = makeRecoveryManager()
    private lazy var subtitleController = makeSubtitleController()

    // MARK: - Core Properties

    private let player = AVPlayer()
    // Retained here: AVAssetResourceLoader holds its delegate weakly.
    private var keyLoader: HlsKeyResourceLoader?
    var playerLayer = AVPlayerLayer()
    var playerConfiguration: PlayerConfiguration!
    weak var delegate: PlayerViewDelegate?

    var streamPosition: TimeInterval? { playerController?.streamPosition }
    var streamDuration: TimeInterval? { playerController?.streamDuration }
    private var playerState: LocalPlayerState { playerController?.playerState ?? .stopped }

    // MARK: - Views

    private let videoView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.background
        return view
    }()
    private let overlay = PlayerOverlayView()
    private let brightnessSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.minimumTrackTintColor = .white
        slider.maximumTrackTintColor = .lightGray
        slider.value = Float(UIScreen.main.brightness)
        slider.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
        slider.setThumbImage(.circle(diameter: 4, color: .white), for: .normal)
        slider.isHidden = true
        return slider
    }()

    // MARK: - Public API

    func setIsPipEnabled(v: Bool) {
        overlay.pipButton.isEnabled = v
    }

    func isHiddenPiP(isPiP: Bool) {
        overlay.isHidden = isPiP
    }

    func setShareEnabled(_ enabled: Bool) {
        overlay.shareButton.isHidden = !enabled
        overlay.shareButton.isEnabled = enabled
    }

    func setSubtitleButtonEnabled(_ enabled: Bool) {
        subtitleController.setEnabled(enabled)
    }

    func setSubtitleFontSizePercent(_ percent: Int) {
        subtitleController.setFontSizePercent(percent)
    }

    func loadSubtitleTrack(_ track: SubtitleTrack?) {
        subtitleController.load(track)
    }

    func loadMedia(autoPlay: Bool, playPosition: TimeInterval, area: UILayoutGuide) {
        translatesAutoresizingMaskIntoConstraints = false
        overlay.setTitle(playerConfiguration.title)
        addSubview(videoView)
        addSubview(subtitleController.overlayView)
        addSubview(overlay)
        addSubview(brightnessSlider)
        makeConstraints(area: area)
        bindControlActions()

        playerController = PlayerController(player: player)
        playerController.delegate = self
        playerController.setPendingPlayPosition(playPosition)
        playerController.pendingPlay = autoPlay

        observerManager = PlayerObserverManager(player: player)
        observerManager.delegate = self

        gestureHandler = PlayerGestureHandler(targetView: self, overlayView: overlay)
        gestureHandler.delegate = self

        controlsCoordinator = PlayerControlsCoordinator(
            playButton: overlay.playButton,
            timeSlider: overlay.timeSlider,
            currentTimeLabel: overlay.currentTimeLabel,
            durationTimeLabel: overlay.durationTimeLabel,
            activityIndicator: overlay.activityIndicator,
            topView: overlay.topView,
            bottomView: overlay.bottomView,
            overlayView: overlay
        )

        overlay.setPlayButtonVisible(false)
        overlay.activityIndicator.startAnimating()
        _ = recoveryManager // arms stall / network / foreground recovery

        guard let sourceURL = URL(string: playerConfiguration.url) else { return }
        playerLayer.removeFromSuperlayer()
        replaceCurrentItem(with: makeAsset(url: sourceURL))
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = bounds
        playerLayer.videoGravity = .resizeAspect
        videoView.layer.insertSublayer(playerLayer, at: 0)
    }

    func changeQuality(url: String?) {
        // `url` carries the variant bandwidth; anything non-numeric means "Auto".
        player.currentItem?.preferredPeakBitRate = url.flatMap(Double.init) ?? 0
    }

    func setSubtitleCurrentItem() -> [String] {
        if let config = playerConfiguration, !config.subtitles.isEmpty {
            return [config.subtitleOffText] + config.subtitles.map(\.label)
        }
        return ["None"] + (player.currentItem?.tracks(type: .subtitle) ?? ["None"])
    }

    func getSubtitleTrackIsEmpty(selectedSubtitleLabel: String) -> Bool {
        return player.currentItem?.select(type: .subtitle, name: selectedSubtitleLabel) != nil
    }

    func changeSpeed(rate: Float) {
        playerController?.changeSpeed(rate: rate)
    }

    func changeConstraints() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let isLandscape = windowScene.interfaceOrientation.isLandscape
        if !isLandscape {
            playerLayer.videoGravity = .resizeAspect
        }
        overlay.showTitleInTopBar(isLandscape)
    }

    // MARK: - Media

    /// Builds the asset, routing AES-128 key requests through `HlsKeyResourceLoader`
    /// when the configuration carries key request headers.
    private func makeAsset(url: URL) -> AVURLAsset {
        let (asset, loader) = HlsKeyResourceLoader.makeAsset(
            url: url,
            keyHeaders: playerConfiguration?.keyRequestHeaders ?? [:]
        )
        keyLoader = loader
        return asset
    }

    /// Swaps in a fresh item for `asset` and re-attaches observers to it.
    private func replaceCurrentItem(with asset: AVURLAsset) {
        observerManager?.removeObservers()
        player.automaticallyWaitsToMinimizeStalling = true
        let item = AVPlayerItem(asset: asset)
        // 0 = automatic: AVPlayer sizes the forward buffer based on network conditions
        item.preferredForwardBufferDuration = 0
        player.replaceCurrentItem(with: item)
        playerController?.setPlayerItem(item)
        observerManager?.addObservers(for: item)
    }

    /// Rebuilds the item from scratch when seek-based stall recovery fails.
    private func reloadCurrentItem(at positionSeconds: Double) {
        guard let url = URL(string: playerConfiguration?.url ?? "") else { return }
        replaceCurrentItem(with: makeAsset(url: url))
        if positionSeconds > 0 {
            playerController?.setPendingPlayPosition(positionSeconds)
            playerController?.pendingPlay = true
        } else {
            player.play()
        }
    }

    private func closePlayer() {
        playerController?.stop()
        playerLayer.removeFromSuperlayer()
        observerManager?.removeObservers()
        let currentSeconds = playerController?.safeIntFromSeconds(playerController?.getCurrentTime() ?? 0) ?? 0
        let durationSeconds = playerController?.safeIntFromSeconds(playerController?.getDuration() ?? 0) ?? 0
        delegate?.close(duration: [currentSeconds, durationSeconds])
    }

    // MARK: - Component Factories

    private func makeRecoveryManager() -> PlaybackRecoveryManager {
        let manager = PlaybackRecoveryManager(player: player)
        manager.onReloadRequired = { [weak self] position in
            self?.reloadCurrentItem(at: position)
        }
        manager.shouldResumePlayback = { [weak self] in
            self?.playerController?.playerState == .playing
        }
        return manager
    }

    private func makeSubtitleController() -> SubtitleController {
        let controller = SubtitleController(player: player)
        controller.layoutProvider = { [weak self] in
            guard let self else { return (.zero, .zero) }
            return (self.playerLayer.videoRect, self.bounds)
        }
        return controller
    }

    // MARK: - Layout & Actions

    private func makeConstraints(area: UILayoutGuide) {
        subtitleController.overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        overlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        overlay.makeConstraints(area: area)
        brightnessSlider.snp.makeConstraints { make in
            make.centerY.equalTo(overlay)
            make.width.equalTo(120)
            make.height.equalTo(12)
            make.left.equalToSuperview().offset(-42)
        }
    }

    private func bindControlActions() {
        func on(_ control: UIControl, _ event: UIControl.Event = .touchUpInside, _ handler: @escaping (PlayerView) -> Void) {
            control.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                handler(self)
            }, for: event)
        }
        on(overlay.exitButton) { $0.closePlayer() }
        on(overlay.pipButton) { $0.delegate?.togglePictureInPictureMode() }
        on(overlay.settingsButton) { $0.delegate?.settingsPressed() }
        on(overlay.shareButton) { $0.delegate?.share() }
        on(overlay.rotateButton) { $0.delegate?.changeOrientation() }
        on(overlay.skipBackwardButton) {
            $0.playerController?.seekBackward(by: 10.0)
            $0.controlsCoordinator?.resetControlsTimer()
        }
        on(overlay.skipForwardButton) {
            $0.playerController?.seekForward(by: 10.0)
            $0.controlsCoordinator?.resetControlsTimer()
        }
        on(overlay.playButton) {
            $0.playerController?.togglePlayPause()
            if $0.playerState == .playing {
                $0.controlsCoordinator?.resetControlsTimer()
            } else {
                $0.controlsCoordinator?.showControls()
            }
        }
        on(overlay.timeSlider, .valueChanged) {
            $0.playerController?.seekToPosition(seconds: Double($0.overlay.timeSlider.value))
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        videoView.frame = bounds
        if playerLayer.superlayer != nil {
            playerLayer.frame = bounds
        }
        subtitleController.layout()
    }

    deinit {
        controlsCoordinator?.invalidateTimers()
        observerManager?.dispose()
        gestureHandler?.removeGestures()
    }
}

// MARK: - PlayerControllerDelegate

extension PlayerView: PlayerControllerDelegate {
    func playerController(_ controller: PlayerController, didUpdatePosition seconds: Double) {
        controlsCoordinator?.updateCurrentTime(seconds: seconds)
    }

    func playerController(_ controller: PlayerController, didUpdateDuration seconds: Double) {
        controlsCoordinator?.updateDuration(seconds: seconds)
    }

    func playerControllerDidFinishPlaying(_ controller: PlayerController) {
        closePlayer()
    }

    func playerController(_ controller: PlayerController, didChangeState state: LocalPlayerState) {
        controlsCoordinator?.updatePlayButton(isPlaying: state == .playing)
    }
}

// MARK: - PlayerObserverDelegate

extension PlayerView: PlayerObserverDelegate {
    func observerManager(_ manager: PlayerObserverManager, didUpdateDuration duration: TimeInterval) {
        controlsCoordinator?.updateDuration(seconds: duration)
        overlay.timeSlider.isEnabled = true
    }

    func observerManager(_ manager: PlayerObserverManager, didUpdateStatus status: AVPlayerItem.Status) {
        if status == .readyToPlay {
            playerController?.handlePlayerReady()
        } else if status == .failed {
            DispatchQueue.main.async { [weak self] in
                self?.controlsCoordinator?.hideLoadingIndicator()
                debugPrint("❌ AVPlayerItem Status Failed: \(self?.player.currentItem?.error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    func observerManager(_ manager: PlayerObserverManager, didChangeTimeControlStatus status: AVPlayer.TimeControlStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Gestures stay enabled in every state: the user must always be able to exit.
            self.gestureHandler?.enableGesture = true
            switch status {
            case .playing, .paused:
                self.recoveryManager.cancelStallRecovery()
                self.controlsCoordinator?.hideLoadingIndicator()
                self.overlay.setPlayButtonVisible(true)
                if status == .playing {
                    self.controlsCoordinator?.resumeAutoHide()
                    self.controlsCoordinator?.resetControlsTimer()
                } else {
                    self.controlsCoordinator?.showControls()
                }
            case .waitingToPlayAtSpecifiedRate:
                self.overlay.setPlayButtonVisible(false)
                self.showStalledState()
            @unknown default:
                break
            }
        }
    }

    func observerManager(_ manager: PlayerObserverManager, didUpdatePosition position: TimeInterval, duration: TimeInterval) {
        controlsCoordinator?.updateSlider(currentSeconds: position, durationSeconds: duration)
        controlsCoordinator?.updateCurrentTime(seconds: position)
        playerController?.updatePosition(position)
    }

    func observerManagerDidFinishPlaying(_ manager: PlayerObserverManager) {
        playerController?.notifyPlaybackFinished()
    }

    func observerManagerDidStall(_ manager: PlayerObserverManager) {
        DispatchQueue.main.async { [weak self] in
            self?.showStalledState()
        }
    }

    func observerManager(_ manager: PlayerObserverManager, didFailWithError error: Error?) {
        debugPrint("❌ Playback failed with error: \(error?.localizedDescription ?? "Unknown")")
    }

    /// Spinner on, controls pinned visible until playback resumes, recovery armed.
    private func showStalledState() {
        controlsCoordinator?.showLoadingIndicator()
        controlsCoordinator?.showControls()
        controlsCoordinator?.suspendAutoHide()
        recoveryManager.scheduleStallRecovery()
    }
}

// MARK: - PlayerGestureDelegate

extension PlayerView: PlayerGestureDelegate {
    func gestureHandlerDidTapToToggleControls(_ handler: PlayerGestureHandler) {
        controlsCoordinator?.toggleControls()
    }

    func gestureHandler(_ handler: PlayerGestureHandler, didTapInZone zone: TapZone) {
        switch zone {
        case .forward:
            playerController?.seekForward(by: 10.0)
        case .backward:
            playerController?.seekBackward(by: 10.0)
        case .center:
            controlsCoordinator?.toggleControls()
        }
    }

    func gestureHandler(_ handler: PlayerGestureHandler, didPinchToScale scale: CGFloat) {
        playerLayer.videoGravity = scale < 0.9 ? .resizeAspect : .resizeAspectFill
        controlsCoordinator?.resetControlsTimer()
    }

    func gestureHandler(_ handler: PlayerGestureHandler, didSwipeVerticallyForBrightness delta: CGFloat) {
        brightnessSlider.isHidden = false
        brightnessSlider.value -= Float(delta)
        UIScreen.main.brightness -= delta
    }

    func gestureHandler(_ handler: PlayerGestureHandler, didSwipeVerticallyForVolume delta: CGFloat) {
        handler.adjustVolume(by: -Float(delta))
    }

    func gestureHandlerDidEndVerticalSwipe(_ handler: PlayerGestureHandler) {
        brightnessSlider.isHidden = true
    }
}

#endif
