//
//  PlayerView.swift
//  video_player
//
//  Refactored to use focused components: PlayerController, PlayerObserverManager,
//  PlayerGestureHandler, and PlayerControlsCoordinator
//

import AVFoundation
import AVKit
import MediaPlayer

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
    
    // Stall recovery
    private var stallRecoveryTimer: Timer?
    
    // MARK: - Core Properties
    private var player = AVPlayer()
    var playerLayer = AVPlayerLayer()
    var playerConfiguration: PlayerConfiguration!
    weak var delegate: PlayerViewDelegate?
    
    // MARK: - Computed Properties (delegated to components)
    var streamPosition: TimeInterval? { playerController?.streamPosition }
    var streamDuration: TimeInterval? { playerController?.streamDuration }
    var playerState: LocalPlayerState { playerController?.playerState ?? .stopped }
    var pendingPlay: Bool {
        get { playerController?.pendingPlay ?? false }
        set { playerController?.pendingPlay = newValue }
    }
    var seeking: Bool { playerController?.seeking ?? false }
    
    // MARK: - UI Elements
    private var videoView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.background
        return view
    }()
    private var overlayView = UIView()
    private var bottomView = UIView()
    private var topView = UIView()
    private var titleLabelPortrait = TitleLabel()
    private var titleLabelLandscape = TitleLabel()
    private var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        return label
    }()
    private var durationTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        return label
    }()
    private var separatorLabel: UILabel = {
        let label = UILabel()
        label.text = " / "
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        return label
    }()
    private lazy var timeSlider: UISlider = {
        let slider = UISlider()
        slider.tintColor = Colors.white
        slider.maximumTrackTintColor = Colors.white27
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        return slider
    }()
    private lazy var rotateButton: IconButton = {
        let button = IconButton()
        if let icon = Svg.rotate {
            button.setImage(icon, for: .normal)
        }
        button.addTarget(self, action: #selector(changeOrientation(_:)), for: .touchUpInside)
        return button
    }()
    private lazy var exitButton: IconButton = {
        let button = IconButton()
        if let icon = Svg.exit {
            button.setImage(icon, for: .normal)
        }
        button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: #selector(exitButtonPressed(_:)), for: .touchUpInside)
        return button
    }()
    private lazy var pipButton: IconButton = {
        let button = IconButton()
        if let icon = Svg.pip {
            button.setImage(icon, for: .normal)
        }
        button.addTarget(self, action: #selector(togglePictureInPictureMode(_:)), for: .touchUpInside)
        return button
    }()
    private lazy var settingsButton: IconButton = {
        let button = IconButton()
        if let icon = Svg.settings {
            button.setImage(icon, for: .normal)
        }
        button.addTarget(self, action: #selector(settingPressed(_:)), for: .touchUpInside)
        return button
    }()
    private lazy var shareButton: IconButton = {
        let button = IconButton()
        if let icon = Svg.share {
            button.setImage(icon, for: .normal)
        }
        button.addTarget(self, action: #selector(share(_:)), for: .touchUpInside)
        return button
    }()
    private lazy var playButton: IconButton = {
        let button = IconButton()
        if let icon = Svg.play {
            button.setImage(icon, for: .normal)
        }
        button.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        button.addTarget(self, action: #selector(playButtonPressed(_:)), for: .touchUpInside)
        return button
    }()
    private lazy var skipForwardButton: IconButton = {
        let button = IconButton()
        if let icon = Svg.forward {
            button.setImage(icon, for: .normal)
        }
        button.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        button.addTarget(self, action: #selector(skipForwardPressed(_:)), for: .touchUpInside)
        return button
    }()
    private lazy var skipBackwardButton: IconButton = {
        let button = IconButton()
        if let icon = Svg.rewind {
            button.setImage(icon, for: .normal)
        }
        button.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        button.addTarget(self, action: #selector(skipBackButtonPressed(_:)), for: .touchUpInside)
        return button
    }()
    private lazy var activityIndicatorView: UIActivityIndicatorView = {
        let activityView = UIActivityIndicatorView(style: .large)
        activityView.color = .white
        return activityView
    }()
    private lazy var brightnessSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.minimumTrackTintColor = UIColor.white
        slider.maximumTrackTintColor = .lightGray
        slider.value = Float(UIScreen.main.brightness)
        slider.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
        slider.isHidden = true
        return slider
    }()
    
    // MARK: - Public API
    
    func setIsPipEnabled(v: Bool) {
        pipButton.isEnabled = v
    }
    
    func isHiddenPiP(isPiP: Bool) {
        overlayView.isHidden = isPiP
    }

    func setShareEnabled(_ enabled: Bool) {
        shareButton.isHidden = !enabled
        shareButton.isEnabled = enabled
    }

    func hasSubtitleTracks() -> Bool {
        guard let currentItem = player.currentItem else { return false }
        return !currentItem.tracks(type: .subtitle).isEmpty
    }
    
    func loadMedia(autoPlay: Bool, playPosition: TimeInterval, area: UILayoutGuide) {
        translatesAutoresizingMaskIntoConstraints = false
        uiSetup()
        addSubviews()
        pinchGesture()
        bottomView.clipsToBounds = true
        timeSlider.clipsToBounds = true
        addConstraints(area: area)
        
        playerController = PlayerController(player: player)
        playerController.delegate = self
        playerController.setPendingPlayPosition(playPosition)
        playerController.pendingPlay = autoPlay
        
        observerManager = PlayerObserverManager(player: player)
        observerManager.delegate = self
        
        gestureHandler = PlayerGestureHandler(targetView: self, overlayView: overlayView)
        gestureHandler.delegate = self
        
        controlsCoordinator = PlayerControlsCoordinator(
            playButton: playButton,
            timeSlider: timeSlider,
            currentTimeLabel: currentTimeLabel,
            durationTimeLabel: durationTimeLabel,
            activityIndicator: activityIndicatorView,
            topView: topView,
            bottomView: bottomView,
            overlayView: overlayView
        )
        
        playButton.alpha = 0.0
        activityIndicatorView.startAnimating()
        loadInitialMediaSource()
        
        // Start network monitoring — auto-recover when connection is restored
        NetworkMonitor.shared.startMonitoring()
        NetworkMonitor.shared.onNetworkStatusChange = { [weak self] isConnected in
            guard let self = self, isConnected else { return }
            // Network restored — attempt stall recovery if player is stuck
            if self.player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                debugPrint("🌐 Network restored — triggering stall recovery")
                self.scheduleStallRecovery()
            }
        }
    }
    
    func changeUrl(url: String?, title: String?) {
        guard let videoURL = URL(string: url ?? "") else { return }
        observerManager?.removeObservers()
        setTitle(title: title)
        let newItem = AVPlayerItem(asset: AVURLAsset(url: videoURL))
        player.replaceCurrentItem(with: newItem)
        player.seek(to: CMTime.zero)
        player.currentItem?.preferredForwardBufferDuration = TimeInterval(5)
        player.automaticallyWaitsToMinimizeStalling = true
        observerManager?.addObservers(for: newItem)
        playerController?.setPlayerItem(newItem)
    }
    
    func changeQuality(url: String?) {
        guard let urlString = url, let bitrate = Double(urlString) else {
            player.currentItem?.preferredPeakBitRate = 0
            return
        }
        player.currentItem?.preferredPeakBitRate = bitrate
    }
    
    func setSubtitleCurrentItem() -> [String] {
        var subtitles = player.currentItem?.tracks(type: .subtitle) ?? ["None"]
        subtitles.insert("None", at: 0)
        return subtitles
    }
    
    func getSubtitleTrackIsEmpty(selectedSubtitleLabel: String) -> Bool {
        return player.currentItem?.select(type: .subtitle, name: selectedSubtitleLabel) != nil
    }
    
    func changeSpeed(rate: Float) {
        playerController?.changeSpeed(rate: rate)
    }
    
    func setTitle(title: String?) {
        titleLabelPortrait.isHidden = false
        titleLabelPortrait.text = title ?? ""
        titleLabelLandscape.text = title ?? ""
    }
    
    func setPlayButton(isPlay: Bool) {
        controlsCoordinator?.updatePlayButton(isPlaying: isPlay)
    }
    
    func setDuration(position: Float) {
        controlsCoordinator?.setSliderValue(position)
        controlsCoordinator?.updateCurrentTime(seconds: Double(position))
    }
    
    func stop() {
        playerController?.stop()
    }
    
    func purgeMediaPlayer() {
        playerController?.stop()
        if playerLayer.superlayer != nil {
            playerLayer.removeFromSuperlayer()
        }
    }
    
    func changeConstraints() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let orientation = windowScene.interfaceOrientation
            if orientation == .landscapeLeft || orientation == .landscapeRight {
                addVideoPortraitConstraints()
            } else {
                addVideoLandscapeConstraints()
            }
        }
    }
    
    // MARK: - Button Actions
    
    @objc func exitButtonPressed(_ sender: UIButton) {
        purgeMediaPlayer()
        observerManager?.removeObservers()
        let currentSeconds = playerController?.safeIntFromSeconds(playerController?.getCurrentTime() ?? 0) ?? 0
        let durationSeconds = playerController?.safeIntFromSeconds(playerController?.getDuration() ?? 0) ?? 0
        delegate?.close(duration: [currentSeconds, durationSeconds])
    }
    
    @objc func togglePictureInPictureMode(_ sender: UIButton) {
        delegate?.togglePictureInPictureMode()
    }
    
    @objc func settingPressed(_ sender: UIButton) {
        delegate?.settingsPressed()
    }
    
    @objc func share(_ sender: UIButton) {
        delegate?.share()
    }
    
    @objc func changeOrientation(_ sender: UIButton) {
        delegate?.changeOrientation()
    }
    
    @objc func skipBackButtonPressed(_ sender: UIButton) {
        playerController?.seekBackward(by: 10.0)
        controlsCoordinator?.resetControlsTimer()
    }
    
    @objc func skipForwardPressed(_ sender: UIButton) {
        playerController?.seekForward(by: 10.0)
        controlsCoordinator?.resetControlsTimer()
    }
    
    @objc func playButtonPressed(_ sender: UIButton) {
        playerController?.togglePlayPause()
        if playerState == .playing {
            controlsCoordinator?.resetControlsTimer()
        } else {
            controlsCoordinator?.showControls()
        }
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {
        playerController?.seekToPosition(seconds: Double(sender.value))
    }
    
    // MARK: - Setup & Helpers
    
    private func uiSetup() {
        setSliderThumbTintColor(Colors.white)
        setTitle(title: playerConfiguration.title)
        // Listen for app foreground — recover player after long background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        // After returning from background (or long inactivity), ensure player recovers
        guard let item = player.currentItem else { return }
        if player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
            // Player is waiting/stalled after foreground — give it a nudge
            let currentTime = player.currentTime()
            player.seek(to: currentTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
                self?.player.play()
            }
        } else if item.status == .readyToPlay && player.timeControlStatus == .paused {
            // Player was playing before background — resume it
            if playerController?.playerState == .playing {
                player.play()
            }
        }
    }
    
    /// Schedule a stall recovery attempt after 8 seconds with exponential backoff
    private func scheduleStallRecovery() {
        // Don't schedule if already has a pending recovery
        guard stallRecoveryTimer == nil || !(stallRecoveryTimer?.isValid ?? false) else { return }
        
        stallRecoveryTimer?.invalidate()
        stallRecoveryTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { [weak self] _ in
            self?.recoverFromStall()
        }
    }
    
    /// Attempt to recover from stall by seeking to current position and re-playing
    private func recoverFromStall() {
        guard player.timeControlStatus == .waitingToPlayAtSpecifiedRate else {
            // Player already recovered on its own
            stallRecoveryTimer = nil
            return
        }
        
        debugPrint("🔄 Stall recovery: attempting seek-and-play")
        let currentTime = player.currentTime()
        
        player.seek(to: currentTime, toleranceBefore: .zero, toleranceAfter: CMTime(seconds: 1, preferredTimescale: 1)) { [weak self] finished in
            guard let self = self else { return }
            if finished {
                self.player.play()
                debugPrint("✅ Stall recovery: player.play() called")
            } else {
                // Seek failed — try a more aggressive recovery: reload current URL
                debugPrint("⚠️ Stall recovery: seek failed, attempting URL reload")
                self.reloadCurrentItem(at: CMTimeGetSeconds(currentTime))
            }
        }
    }
    
    /// Reload AVPlayerItem from scratch when seek-based recovery fails
    private func reloadCurrentItem(at positionSeconds: Double) {
        guard let urlString = playerConfiguration?.url,
              let url = URL(string: urlString) else { return }
        
        observerManager?.removeObservers()
        let newItem = AVPlayerItem(asset: AVURLAsset(url: url))
        player.replaceCurrentItem(with: newItem)
        player.currentItem?.preferredForwardBufferDuration = TimeInterval(5)
        playerController?.setPlayerItem(newItem)
        observerManager?.addObservers(for: newItem)
        
        // Seek to where we left off once ready
        if positionSeconds > 0 {
            playerController?.setPendingPlayPosition(positionSeconds)
            playerController?.pendingPlay = true
        } else {
            player.play()
        }
    }

    private func loadInitialMediaSource() {
        guard let playerConfiguration else { return }
        guard let sourceURL = URL(string: playerConfiguration.url) else { return }

        let canShare = !playerConfiguration.playVideoFromAsset &&
            !playerConfiguration.movieShareLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        setShareEnabled(canShare)
        loadMediaPlayer(asset: AVURLAsset(url: sourceURL))
    }
    
    private func loadMediaPlayer(asset: AVURLAsset) {
        observerManager?.removeObservers()
        if playerLayer.superlayer != nil {
            playerLayer.removeFromSuperlayer()
        }
        player.automaticallyWaitsToMinimizeStalling = true
        let newItem = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: newItem)
        player.currentItem?.preferredForwardBufferDuration = TimeInterval(5)
        playerController?.setPlayerItem(newItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = bounds
        playerLayer.videoGravity = .resizeAspect
        videoView.layer.insertSublayer(playerLayer, at: 0)
        observerManager?.addObservers(for: newItem)
    }
    
    private func pinchGesture() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didpinch))
        videoView.addGestureRecognizer(pinchGesture)
    }
    
    @objc func didpinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            playerLayer.videoGravity = gesture.scale < 0.9 ? .resizeAspect : .resizeAspectFill
            controlsCoordinator?.resetControlsTimer()
        }
    }
    
    private func setSliderThumbTintColor(_ color: UIColor) {
        let circle = makeCircleWith(size: CGSize(width: 4, height: 4), backgroundColor: UIColor.white)
        brightnessSlider.setThumbImage(circle, for: .normal)
        let circleImage = makeCircleWithBorder(size: CGSize(width: 20, height: 20), backgroundColor: color)
        timeSlider.setThumbImage(circleImage, for: .normal)
    }
    
    private func makeCircleWith(size: CGSize, backgroundColor: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(backgroundColor.cgColor)
        context?.setStrokeColor(UIColor.clear.cgColor)
        let bounds = CGRect(origin: .zero, size: size)
        context?.addEllipse(in: bounds)
        context?.drawPath(using: .fill)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private func makeCircleWithBorder(size: CGSize, backgroundColor: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(backgroundColor.cgColor)
        context?.setStrokeColor(UIColor.clear.cgColor)
        let bounds = CGRect(origin: .zero, size: size)
        context?.addEllipse(in: bounds)
        context?.drawPath(using: .fill)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private func addVideoPortraitConstraints() {
        titleLabelLandscape.isHidden = false
        titleLabelPortrait.isHidden = true
    }
    
    private func addVideoLandscapeConstraints() {
        playerLayer.videoGravity = .resizeAspect
        titleLabelLandscape.isHidden = true
        titleLabelPortrait.isHidden = false
    }
    
    private func addSubviews() {
        addSubview(videoView)
        addSubview(overlayView)
        addSubview(brightnessSlider)
        overlayView.addSubview(topView)
        overlayView.addSubview(playButton)
        overlayView.addSubview(skipForwardButton)
        overlayView.addSubview(skipBackwardButton)
        overlayView.addSubview(activityIndicatorView)
        overlayView.addSubview(bottomView)
        overlayView.addSubview(titleLabelPortrait)
        addTopViewSubviews()
        addBottomViewSubviews()
    }
    
    private func addTopViewSubviews() {
        topView.addSubview(exitButton)
        topView.addSubview(titleLabelLandscape)
        topView.addSubview(settingsButton)
        topView.addSubview(shareButton)
        topView.addSubview(pipButton)
    }
    
    private func addBottomViewSubviews() {
        bottomView.addSubview(currentTimeLabel)
        bottomView.addSubview(durationTimeLabel)
        bottomView.addSubview(separatorLabel)
        bottomView.addSubview(timeSlider)
        bottomView.addSubview(rotateButton)
    }
    
    private func addConstraints(area: UILayoutGuide) {
        addBottomViewConstraints(area: area)
        addTopViewConstraints(area: area)
        addControlButtonConstraints()
    }
    
    private func addControlButtonConstraints() {
        brightnessSlider.snp.makeConstraints { make in
            make.centerY.equalTo(overlayView)
            make.width.equalTo(120)
            make.height.equalTo(12)
            make.left.equalToSuperview().offset(-42)
        }
        playButton.snp.makeConstraints { make in
            make.centerX.equalTo(overlayView)
            make.centerY.equalTo(overlayView)
        }
        skipBackwardButton.snp.makeConstraints { make in
            make.right.equalTo(playButton.snp.left).offset(-60)
            make.top.equalTo(playButton)
        }
        skipForwardButton.snp.makeConstraints { make in
            make.left.equalTo(playButton.snp.right).offset(60)
            make.top.equalTo(playButton)
        }
        activityIndicatorView.snp.makeConstraints { make in
            make.centerX.equalTo(overlayView)
            make.centerY.equalTo(overlayView)
        }
        activityIndicatorView.layer.cornerRadius = 20
    }
    
    private func addBottomViewConstraints(area: UILayoutGuide) {
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        bottomView.snp.makeConstraints { make in
            make.trailing.equalTo(area).offset(0)
            make.leading.equalTo(area).offset(0)
            make.bottom.equalTo(area).offset(0)
        }
        timeSlider.snp.makeConstraints { make in
            make.bottom.equalTo(bottomView).offset(-8)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
        }
        rotateButton.snp.makeConstraints { make in
            make.right.equalTo(bottomView).offset(0)
            make.bottom.equalTo(timeSlider.snp.top).offset(0)
            make.top.greaterThanOrEqualTo(bottomView).offset(8)
        }
        currentTimeLabel.snp.makeConstraints { make in
            make.left.equalTo(bottomView).offset(8)
            make.centerY.equalTo(rotateButton)
        }
        separatorLabel.snp.makeConstraints { make in
            make.left.equalTo(currentTimeLabel.snp.right)
            make.centerY.equalTo(currentTimeLabel)
        }
        durationTimeLabel.snp.makeConstraints { make in
            make.left.equalTo(separatorLabel.snp.right)
            make.centerY.equalTo(separatorLabel)
        }
    }
    
    private func addTopViewConstraints(area: UILayoutGuide) {
        topView.snp.makeConstraints { make in
            make.leading.equalTo(area).offset(0)
            make.trailing.equalTo(area).offset(0)
            make.top.equalTo(area).offset(0)
            make.height.equalTo(48)
        }
        exitButton.snp.makeConstraints { make in
            make.left.equalTo(topView)
            make.centerY.equalTo(topView)
        }
        settingsButton.snp.makeConstraints { make in
            make.right.equalTo(topView)
            make.centerY.equalTo(topView)
        }
        shareButton.snp.makeConstraints { make in
            make.right.equalTo(settingsButton.snp.left)
            make.centerY.equalTo(topView)
        }
        pipButton.snp.makeConstraints { make in
            make.left.equalTo(exitButton.snp.right)
            make.centerY.equalTo(topView)
        }
        titleLabelLandscape.snp.makeConstraints { make in
            make.centerY.equalTo(topView)
            make.centerX.equalTo(topView)
            make.left.equalTo(pipButton.snp.right).offset(8)
        }
        titleLabelPortrait.snp.makeConstraints { make in
            make.centerX.equalTo(overlayView)
            make.top.equalTo(topView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoView.frame = bounds
        overlayView.frame = bounds
        if playerLayer.superlayer != nil {
            playerLayer.frame = bounds
        }
    }
    
    deinit {
        stallRecoveryTimer?.invalidate()
        stallRecoveryTimer = nil
        NotificationCenter.default.removeObserver(self)
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
        purgeMediaPlayer()
        observerManager?.removeObservers()
        let currentSeconds = controller.safeIntFromSeconds(controller.getCurrentTime())
        let durationSeconds = controller.safeIntFromSeconds(controller.getDuration())
        delegate?.close(duration: [currentSeconds, durationSeconds])
    }
    
    func playerController(_ controller: PlayerController, didChangeState state: LocalPlayerState) {
        controlsCoordinator?.updatePlayButton(isPlaying: state == .playing)
    }
}

// MARK: - PlayerObserverDelegate

extension PlayerView: PlayerObserverDelegate {
    func observerManager(_ manager: PlayerObserverManager, didUpdateDuration duration: TimeInterval) {
        controlsCoordinator?.updateDuration(seconds: duration)
        timeSlider.isEnabled = true
    }
    
    func observerManager(_ manager: PlayerObserverManager, didUpdateStatus status: AVPlayerItem.Status) {
        if status == .readyToPlay {
            playerController?.handlePlayerReady()
        } else if status == .failed {
            // Show error in UI
            DispatchQueue.main.async { [weak self] in
                self?.controlsCoordinator?.hideLoadingIndicator()
                // You could show an alert or toast here
                debugPrint("❌ AVPlayerItem Status Failed: \(self?.player.currentItem?.error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func observerManager(_ manager: PlayerObserverManager, didChangeTimeControlStatus status: AVPlayer.TimeControlStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch status {
            case .playing:
                // ✅ Player resumed — cancel any pending recovery timer
                self.stallRecoveryTimer?.invalidate()
                self.stallRecoveryTimer = nil
                self.controlsCoordinator?.hideLoadingIndicator()
                self.playButton.alpha = self.skipBackwardButton.alpha
                // ✅ ALWAYS keep gestures enabled — never lock user out
                self.gestureHandler?.enableGesture = true
                self.controlsCoordinator?.resetControlsTimer()
            case .paused:
                self.stallRecoveryTimer?.invalidate()
                self.stallRecoveryTimer = nil
                self.controlsCoordinator?.hideLoadingIndicator()
                self.playButton.alpha = self.skipBackwardButton.alpha
                self.gestureHandler?.enableGesture = true
                self.controlsCoordinator?.showControls()
            case .waitingToPlayAtSpecifiedRate:
                self.controlsCoordinator?.showLoadingIndicator()
                self.playButton.alpha = 0.0
                // ✅ DO NOT disable gestures — user must be able to exit at any time
                // gestureHandler?.enableGesture = false  ← was causing player lockout
                self.controlsCoordinator?.showControls()  // Show controls so user can see loading
                // Start stall recovery timer — try to recover after 8 seconds
                self.scheduleStallRecovery()
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
            guard let self = self else { return }
            self.controlsCoordinator?.showLoadingIndicator()
            self.controlsCoordinator?.showControls()  // Keep controls visible during stall
            self.scheduleStallRecovery()
        }
    }
    
    func observerManager(_ manager: PlayerObserverManager, didFailWithError error: Error?) {
        // Handle playback failure
        debugPrint("❌ Playback failed with error: \(error?.localizedDescription ?? "Unknown")")
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
