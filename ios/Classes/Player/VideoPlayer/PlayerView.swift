//
//  PlayerView.swift
//  video_player
//
//  Created by Sunnatillo Shavkatov on 13/11/22.
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

    private var player = AVPlayer()
    var playerLayer = AVPlayerLayer()
    private var mediaTimeObserver: Any?
    private var observingMediaPlayer: Bool = false
    var playerConfiguration: PlayerConfiguration!
    weak var delegate: PlayerViewDelegate?

    private var timer: Timer?
    private var seekForwardTimer: Timer?
    private var seekBackwardTimer: Timer?
    private var swipeGesture: UIPanGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    private var tapHideGesture: UITapGestureRecognizer!
    private var panDirection = SwipeDirection.vertical
    private var isVolume = false
    private var volumeViewSlider: UISlider!
    private var brightnessViewSlider: UISlider!
    ///
    private(set) var streamPosition: TimeInterval?
    private(set) var streamDuration: TimeInterval?
    ///
    private(set) var playerState = LocalPlayerState.stopped
    // If there is a pending request to seek to a new position.
    private var pendingPlayPosition = TimeInterval()
    // If there is a pending request to start playback.
    var pendingPlay: Bool = false
    var seeking: Bool = false

    private var videoView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.background
        return view
    }()

    private var overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private var topView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private var titleLabelPortrait: TitleLabel = TitleLabel()
    private var titleLabelLandscape: TitleLabel = TitleLabel()

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
        button.addTarget(self, action: #selector(skipForwardButtonPressed(_:)), for: .touchUpInside)
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

    private var activityIndicatorView: UIActivityIndicatorView = {
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

    private func configureVolume() {
        let volumeView = MPVolumeView()
        for view in volumeView.subviews {
            if let slider = view as? UISlider {
                self.volumeViewSlider = slider
                self.brightnessViewSlider = slider
            }
        }
    }

    private var playerRate: Float = 1.0
    private var enableGesture = true
    private var backwardGestureTimer: Timer?
    private var forwardGestureTimer: Timer?
    private var backwardTouches = 0
    private var forwardTouches = 0

    func setIsPipEnabled(v: Bool) {
        pipButton.isEnabled = v
    }

    func isHiddenPiP(isPiP: Bool) {
        overlayView.isHidden = isPiP
    }

    func loadMedia(autoPlay: Bool, playPosition: TimeInterval, area: UILayoutGuide) {
        translatesAutoresizingMaskIntoConstraints = false
        uiSetup()
        addSubviews()
        pinchGesture()
        bottomView.clipsToBounds = true
        timeSlider.clipsToBounds = true
        addConstraints(area: area)
        addGestures()
        playButton.alpha = 0.0
        activityIndicatorView.startAnimating()
        pendingPlayPosition = playPosition
        pendingPlay = autoPlay
        playOfflineAsset()
    }

    private func uiSetup() {
        configureVolume()

        setSliderThumbTintColor(Colors.white)

        setTitle(title: playerConfiguration.title)
    }

    fileprivate func makeCircleWith(size: CGSize, backgroundColor: UIColor) -> UIImage? {
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

    fileprivate func makeCircleWithBorder(size: CGSize, backgroundColor: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()

        // Draw the circle with background color
        context?.setFillColor(backgroundColor.cgColor)
        context?.setStrokeColor(UIColor.clear.cgColor)
        let bounds = CGRect(origin: .zero, size: size)
        context?.addEllipse(in: bounds)
        context?.drawPath(using: .fill)

        // Get the image from the context
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    private func setSliderThumbTintColor(_ color: UIColor) {
        let circle = makeCircleWith(
            size: CGSize(width: 4, height: 4),
            backgroundColor: UIColor.white)
        brightnessSlider.setThumbImage(circle, for: .normal)
        ///
        let circleImage = makeCircleWithBorder(
            size: CGSize(width: 20, height: 20),
            backgroundColor: color)
        timeSlider.setThumbImage(circleImage, for: .normal)
    }

    private func loadMediaPlayer(asset: AVURLAsset) {
        player.automaticallyWaitsToMinimizeStalling = true
        player.replaceCurrentItem(with: AVPlayerItem(asset: asset))
        player.currentItem?.preferredForwardBufferDuration = TimeInterval(5)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = bounds
        if let videoTrack = player.currentItem?.asset.tracks(withMediaType: .video).first {
            let videoSize = videoTrack.naturalSize
            let videoAspectRatio = videoSize.width / videoSize.height

            if videoAspectRatio > 1 {
                // Landscape video
                playerLayer.frame.size.width = videoView.bounds.width
                playerLayer.frame.size.height = videoView.bounds.width / videoAspectRatio
            } else {
                // Portrait video
                playerLayer.frame.size.height = videoView.bounds.height
                playerLayer.frame.size.width = videoView.bounds.height * videoAspectRatio
            }
        }

        playerLayer.videoGravity = .resizeAspect
        videoView.layer.addSublayer(playerLayer)
        layer.insertSublayer(playerLayer, above: videoView.layer)

        NotificationCenter.default.addObserver(self, selector: #selector(playerEndedPlaying), name: Notification.Name("AVPlayerItemDidPlayToEndTimeNotification"), object: nil)
        addTimeObserver()
    }

    private func playOfflineAsset() {
        guard let url = URL(string: playerConfiguration.url) else {
            return
        }
        loadMediaPlayer(asset: AVURLAsset(url: url))
    }

    func changeUrl(url: String?, title: String?) {
        guard let videoURL = URL(string: url ?? "") else {
            return
        }
        self.setTitle(title: title)
        self.player.replaceCurrentItem(with: AVPlayerItem(asset: AVURLAsset(url: videoURL)))
        self.player.seek(to: CMTime.zero)
        self.player.currentItem?.preferredForwardBufferDuration = TimeInterval(5)
        self.player.automaticallyWaitsToMinimizeStalling = true
        self.player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
    }

    func changeQuality(url: String?) {
        if url == nil { return }
        guard let bitrate = Double(url!) else {
            self.player.currentItem?.preferredPeakBitRate = 0
            return
        }
        self.player.currentItem?.preferredPeakBitRate = bitrate
    }

    func setSubtitleCurrentItem() -> [String] {
        var subtitles = player.currentItem?.tracks(type: .subtitle) ?? ["None"]
        subtitles.insert("None", at: 0)
        return subtitles
    }

    func getSubtitleTrackIsEmpty(selectedSubtitleLabel: String) -> Bool {
        return (player.currentItem?.select(type: .subtitle, name: selectedSubtitleLabel)) != nil
    }

    func changeSpeed(rate: Float) {
        self.playerRate = rate
        self.player.preroll(atRate: self.playerRate, completionHandler: nil)
        self.player.rate = Float(self.playerRate)
    }

    func setTitle(title: String?) {
        self.titleLabelPortrait.isHidden = false
        self.titleLabelPortrait.text = title ?? ""
        self.titleLabelLandscape.text = title ?? ""
    }

    private func safeIntFromSeconds(_ seconds: Double) -> Int {
        guard seconds.isFinite && !seconds.isNaN else {
            return 0
        }
        return Int(seconds)
    }

    @objc func exitButtonPressed(_ sender: UIButton) {
        purgeMediaPlayer()
        removeMediaPlayerObservers()
        // Safe conversion
        let currentSeconds = safeIntFromSeconds(player.currentTime().seconds)
        let durationSeconds = safeIntFromSeconds(player.currentItem?.duration.seconds ?? 0)
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
        self.backwardTouches += 1
        self.seekBackwardTo(10.0 * Double(self.backwardTouches))
        self.backwardGestureTimer?.invalidate()
        self.backwardGestureTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            self.backwardTouches = 0
        }
        resetTimer()
    }

    @objc func skipForwardButtonPressed(_ sender: UIButton) {
        self.forwardTouches += 1
        self.seekForwardTo(10.0 * Double(self.forwardTouches))
        self.forwardGestureTimer?.invalidate()
        self.forwardGestureTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            self.forwardTouches = 0
        }
        resetTimer()
    }

    @objc func playButtonPressed(_ sender: UIButton) {
        if !player.isPlaying {
            player.play()
            playButton.setImage(Svg.pause!, for: .normal)
            self.player.preroll(atRate: Float(self.playerRate), completionHandler: nil)
            self.player.rate = Float(self.playerRate)
            resetTimer()
        } else {
            playButton.setImage(Svg.play!, for: .normal)
            player.pause()
            timer?.invalidate()
            showControls()
        }
    }

    @objc func hideControls() {
        let options: UIView.AnimationOptions = [.curveEaseIn]
        UIView.animate(
            withDuration: 0.3, delay: 0.2, options: options,
            animations: { [self] in
                let alpha = 0.0
                topView.alpha = alpha
                skipForwardButton.alpha = alpha
                overlayView.alpha = alpha
                if enableGesture {
                    playButton.alpha = alpha
                }
                skipBackwardButton.alpha = alpha
                bottomView.alpha = alpha
            }, completion: nil)
    }

    @objc func hideSeekForwardButton() {
        if topView.alpha == 0 {
            let options: UIView.AnimationOptions = [.curveEaseIn]
            UIView.animate(
                withDuration: 0.1, delay: 0.1, options: options,
                animations: { [self] in
                    let alpha = 0.0
                    skipForwardButton.alpha = alpha
                }, completion: nil)
        }
    }

    @objc func hideSeekBackwardButton() {
        if topView.alpha == 0 {
            let options: UIView.AnimationOptions = [.curveEaseIn]
            UIView.animate(
                withDuration: 0.1, delay: 0.1, options: options,
                animations: { [self] in
                    let alpha = 0.0
                    skipBackwardButton.alpha = alpha
                }, completion: nil)
        }
    }

    private func showControls() {
        let options: UIView.AnimationOptions = [.curveEaseIn]
        UIView.animate(
            withDuration: 0.3, delay: 0.2, options: options,
            animations: { [self] in
                let alpha = 1.0
                topView.alpha = alpha
                skipForwardButton.alpha = alpha
                skipBackwardButton.alpha = alpha
                if enableGesture {
                    playButton.alpha = alpha
                }
                bottomView.alpha = alpha
            }, completion: nil)

    }

    private func resetTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
    }

    private func pinchGesture() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didpinch))
        videoView.addGestureRecognizer(pinchGesture)
    }

    @objc func didpinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            let scale = gesture.scale
            if scale < 0.9 {
                self.playerLayer.videoGravity = .resizeAspect
            } else {
                self.playerLayer.videoGravity = .resizeAspectFill
            }
            resetTimer()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        videoView.frame = fullFrame()
        overlayView.frame = fullFrame()
        playerLayer.frame = fullFrame()
    }

    private func fullFrame() -> CGRect {
        return bounds
    }

    override func updateConstraints() {
        super.updateConstraints()
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

    private func addVideoPortraitConstraints() {
        titleLabelLandscape.isHidden = false
        titleLabelPortrait.isHidden = true
    }

    private func addVideoLandscapeConstraints() {
        self.playerLayer.videoGravity = .resizeAspect
        titleLabelLandscape.isHidden = true
        titleLabelPortrait.isHidden = false
    }

    private func addGestures() {
        swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(swipePan))
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureControls))
        addGestureRecognizer(swipeGesture)
        addGestureRecognizer(tapGesture)
    }

    private func addSubviews() {
        addSubview(videoView)
        addSubview(overlayView)
        addSubview(brightnessSlider)
        overlayView.addSubview(topView)
        overlayView.addSubview(playButton)
        overlayView.addSubview(skipForwardButton)
        overlayView.addSubview(skipForwardButton)
        overlayView.addSubview(skipBackwardButton)
        overlayView.addSubview(skipBackwardButton)
        overlayView.addSubview(activityIndicatorView)
        overlayView.addSubview(bottomView)
        overlayView.addSubview(rotateButton)
        overlayView.addSubview(topView)
        overlayView.addSubview(titleLabelPortrait)
        addTopViewSubviews()
        addBottomViewSubviews()
    }

    // MARK: - addBottomViewSubviews
    private func addBottomViewSubviews() {
        bottomView.addSubview(currentTimeLabel)
        bottomView.addSubview(durationTimeLabel)
        bottomView.addSubview(separatorLabel)
        bottomView.addSubview(timeSlider)
        bottomView.addSubview(rotateButton)
    }

    private func addTopViewSubviews() {
        topView.addSubview(exitButton)
        topView.addSubview(titleLabelLandscape)
        topView.addSubview(settingsButton)
        topView.addSubview(shareButton)
        topView.addSubview(pipButton)
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
            make.height.equalTo(82)
        }

        timeSlider.snp.makeConstraints { make in
            make.bottom.equalTo(bottomView).offset(-8)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
        }

        rotateButton.snp.makeConstraints { make in
            make.bottom.equalTo(timeSlider.snp.top).offset(-8)
            make.right.equalTo(bottomView).offset(0)
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
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(16)
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "duration" {
            if let duration = player.currentItem?.duration.seconds,
               duration.isFinite && !duration.isNaN && duration > 0.0 {
                self.durationTimeLabel.text = VGPlayerUtils.getTimeString(from: player.currentItem!.duration)
            } else {
                if let item = player.currentItem,
                   let seekableRange = item.seekableTimeRanges.last?.timeRangeValue {
                    let endTime = CMTimeAdd(seekableRange.start, seekableRange.duration)
                    let seconds = CMTimeGetSeconds(endTime)
                    if seconds.isFinite && !seconds.isNaN && seconds > 0 {
                        self.durationTimeLabel.text = VGPlayerUtils.getTimeString(from: endTime)
                    }
                }
            }
        }

        // STATUS
        if keyPath == "status" {
            if player.status == .readyToPlay {
                handleMediaPlayerReady()
            } else if player.status == .failed {
                // Player failed
            }
        }

        // TIME CONTROL STATUS
        if keyPath == "timeControlStatus", let change = change,
           let newValue = change[NSKeyValueChangeKey.newKey] as? Int,
           let oldValue = change[NSKeyValueChangeKey.oldKey] as? Int {

            if newValue != oldValue {
                DispatchQueue.main.async { [weak self] in
                    if newValue == 2 {
                        self?.playButton.setImage(Svg.pause!, for: .normal)
                        self?.playButton.alpha = self?.skipBackwardButton.alpha ?? 0.0
                        self?.activityIndicatorView.stopAnimating()
                        self?.enableGesture = true
                    } else if newValue == 0 {
                        self?.playButton.setImage(Svg.play!, for: .normal)
                        self?.playButton.alpha = self?.skipBackwardButton.alpha ?? 0.0
                        self?.activityIndicatorView.stopAnimating()
                        self?.enableGesture = true
                        self?.timer?.invalidate()
                        self?.showControls()
                    } else {
                        self?.playButton.alpha = 0.0
                        self?.activityIndicatorView.startAnimating()
                        self?.enableGesture = false
                    }
                }
            }
        }
    }

    private func handleMediaPlayerReady() {
        if let duration = player.currentItem?.duration, CMTIME_IS_INDEFINITE(duration) {
            purgeMediaPlayer()
            playOfflineAsset()
            return
        }

        if streamDuration == nil {
            if let duration = player.currentItem?.duration {
                let durationSeconds = CMTimeGetSeconds(duration)
                if durationSeconds.isFinite && !durationSeconds.isNaN && durationSeconds > 0 {
                    streamDuration = durationSeconds
                    DispatchQueue.main.async { [weak self] in
                        if let streamDuration = self?.streamDuration {
                            self?.timeSlider.maximumValue = Float(streamDuration)
                            self?.timeSlider.minimumValue = 0
                            let safePosition = self?.pendingPlayPosition ?? 0
                            if safePosition.isFinite && !safePosition.isNaN && safePosition >= 0 {
                                self?.timeSlider.value = Float(safePosition)
                            } else {
                                self?.timeSlider.value = 0
                            }
                            self?.timeSlider.isEnabled = true
                        }
                    }
                } else {
                    if let item = player.currentItem,
                       let seekableRange = item.seekableTimeRanges.last?.timeRangeValue {
                        let endTime = CMTimeAdd(seekableRange.start, seekableRange.duration)
                        let seconds = CMTimeGetSeconds(endTime)
                        if seconds.isFinite && !seconds.isNaN && seconds > 0 {
                            streamDuration = seconds
                            DispatchQueue.main.async { [weak self] in
                                self?.timeSlider.maximumValue = Float(seconds)
                                self?.timeSlider.minimumValue = 0
                                self?.timeSlider.value = 0
                                self?.timeSlider.isEnabled = true
                            }
                        }
                    }
                }
            }
        }

        if let pendingPosition = pendingPlayPosition as Double?,
           pendingPosition.isFinite && !pendingPosition.isNaN && pendingPosition > 0 {
            let seekTime = CMTimeMakeWithSeconds(pendingPosition, preferredTimescale: 600)
            player.seek(to: seekTime) { [weak self] completed in
                DispatchQueue.main.async {
                    if completed {
                        if self?.playerState == .starting {
                            self?.pendingPlay = true
                        }
                        self?.handleSeekFinished()
                    } else {
                        self?.activityIndicatorView.stopAnimating()
                    }
                }
            }
            return
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.activityIndicatorView.stopAnimating()
            }
        }

        if pendingPlay {
            pendingPlay = false
            player.play()
            playerState = .playing
        } else {
            playerState = .paused
        }
    }

    private func handleSeekFinished() {
        activityIndicatorView.stopAnimating()
        if pendingPlay {
            pendingPlay = false
            player.play()
            playerState = .playing
        } else {
            playerState = .paused
        }
        seeking = false
    }

    func setPlayButton(isPlay: Bool) {
        if isPlay {
            playButton.setImage(Svg.pause!, for: .normal)
        } else {
            playButton.setImage(Svg.play!, for: .normal)
        }
    }

    func setDuration(position: Float) {
        timeSlider.value = position
        currentTimeLabel.text = VGPlayerUtils.getTimeString(from: CMTimeMake(value: Int64(position), timescale: 1))
    }

    @objc func playerEndedPlaying(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.player.seek(to: CMTime.zero)
            self?.playButton.setImage(Svg.play!, for: .normal)
        }
    }

    @objc func swipePan() {
        let locationPoint = swipeGesture.location(in: overlayView)
        let velocityPoint = swipeGesture.velocity(in: overlayView)
        switch swipeGesture.state {
        case .began:
            let x = abs(velocityPoint.x)
            let y = abs(velocityPoint.y)

            if x > y {
                panDirection = SwipeDirection.horizontal
            } else {
                panDirection = SwipeDirection.vertical
                if locationPoint.x > overlayView.bounds.size.width / 2 {
                    isVolume = true
                } else {
                    isVolume = false
                }
            }

        case UIGestureRecognizer.State.changed:
            switch panDirection {
            case SwipeDirection.horizontal:
                //                horizontalMoved(velocityPoint.x)
                break
            case SwipeDirection.vertical:
                verticalMoved(velocityPoint.y)
                break
            }

        case UIGestureRecognizer.State.ended:
            switch panDirection {
            case SwipeDirection.horizontal:
                brightnessSlider.isHidden = true
                break
            case SwipeDirection.vertical:
                brightnessSlider.isHidden = true
                isVolume = false
                break
            }
        default:
            break
        }
    }

    private func verticalMoved(_ value: CGFloat) {
        if isVolume {
            self.volumeViewSlider.value -= Float(value / 10000)
        } else {
            brightnessSlider.isHidden = false
            brightnessSlider.value -= Float(value / 10000)
            UIScreen.main.brightness -= value / 10000
        }
    }

    private func showBlockControls() {
        let options: UIView.AnimationOptions = [.curveEaseIn]
        UIView.animate(
            withDuration: 0.3, delay: 0.2, options: options,
            animations: { [self] in
                let alpha = 1.0
                topView.alpha = alpha
                resetTimer()
            }, completion: nil)
    }

    private func toggleViews() {
        let options: UIView.AnimationOptions = [.curveEaseIn]
        UIView.animate(
            withDuration: 0.05, delay: 0, options: options,
            animations: { [self] in
                let alpha = topView.alpha == 0.0 ? 1.0 : 0.0
                topView.alpha = alpha
                overlayView.alpha = alpha
                skipForwardButton.alpha = alpha
                skipBackwardButton.alpha = alpha
                if enableGesture {
                    playButton.alpha = alpha
                }
                bottomView.alpha = alpha
                if alpha == 1.0 {
                    resetTimer()
                }
            }, completion: nil)
    }

    private func fastForward() {
        self.forwardTouches += 1
        if forwardTouches < 2 {
            self.forwardGestureTimer?.invalidate()
            self.forwardGestureTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                self.forwardTouches = 0
                self.toggleViews()
            }
        } else {
            self.showSeekForwardButton()
            self.seekForwardTo(10.0 * Double(self.forwardTouches))
            self.forwardGestureTimer?.invalidate()
            self.forwardGestureTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                self.forwardTouches = 0
                self.resetSeekForwardTimer()
            }
        }
    }

    private func fastBackward() {
        self.backwardTouches += 1
        if backwardTouches < 2 {
            self.backwardGestureTimer?.invalidate()
            self.backwardGestureTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                self.backwardTouches = 0
                self.toggleViews()
            }
        } else {
            self.showSeekBackwardButton()
            self.seekBackwardTo(10.0 * Double(self.backwardTouches))
            self.backwardGestureTimer?.invalidate()
            self.backwardGestureTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                self.backwardTouches = 0
                self.resetSeekBackwardTimer()
            }
        }
    }

    private func resetSeekForwardTimer() {
        seekForwardTimer?.invalidate()
        seekForwardTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(hideSeekForwardButton), userInfo: nil, repeats: false)
    }

    private func resetSeekBackwardTimer() {
        seekBackwardTimer?.invalidate()
        seekBackwardTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(hideSeekBackwardButton), userInfo: nil, repeats: false)
    }

    private func showSeekForwardButton() {
        skipForwardButton.alpha = 1.0
    }

    private func showSeekBackwardButton() {
        skipBackwardButton.alpha = 1.0
    }

    @objc func tapGestureControls() {
        let location = tapGesture.location(in: overlayView)
        if location.x > overlayView.bounds.width / 2 + 50 {
            self.fastForward()
        } else if location.x <= overlayView.bounds.width / 2 - 50 {
            self.fastBackward()
        } else {
            toggleViews()
        }
    }

    fileprivate func seekForwardTo(_ seekPosition: Double) {
        guard let duration = player.currentItem?.duration else { return }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime + seekPosition
        if newTime < (CMTimeGetSeconds(duration) - seekPosition) {
            let time: CMTime = CMTimeMake(value: Int64(newTime * 1000), timescale: 1000)
            player.seek(to: time)
        }
    }

    fileprivate func seekBackwardTo(_ seekPosition: Double) {
        let currentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = currentTime - seekPosition
        if newTime < 0 {
            newTime = 0
        }
        let time: CMTime = CMTimeMake(value: Int64(newTime * 1000), timescale: 1000)
        player.seek(to: time)
    }

    @objc func sliderValueChanged(_ sender: UISlider) {
        player.seek(to: CMTimeMake(value: Int64(sender.value * 1000), timescale: 1000))
    }

    @objc func playerDidFinishPlaying() {
        purgeMediaPlayer()
        removeMediaPlayerObservers()
        delegate?.close(duration: [
            Int(player.currentTime().seconds),
            Int(player.currentItem!.duration.seconds),
        ]
        )
    }

    /// MARK: - Time logic
    private func addTimeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem)
        player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
        player.currentItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        player.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let mainQueue = DispatchQueue.main

        mediaTimeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: mainQueue,
            using: { [weak self] time in
                guard let self = self,
                      let currentItem = self.player.currentItem else { return }
                let duration = currentItem.duration
                let durationSeconds = CMTimeGetSeconds(duration)
                guard duration.isValid,
                      !CMTIME_IS_INDEFINITE(duration),
                      durationSeconds.isFinite,
                      !durationSeconds.isNaN,
                      durationSeconds > 0 else {
                    if let seekableRange = currentItem.seekableTimeRanges.last?.timeRangeValue {
                        let endTime = CMTimeAdd(seekableRange.start, seekableRange.duration)
                        let seekableSeconds = CMTimeGetSeconds(endTime)
                        if seekableSeconds.isFinite && !seekableSeconds.isNaN && seekableSeconds > 0 {
                            self.timeSlider.maximumValue = Float(seekableSeconds)
                        }
                    }
                    return
                }
                let currentTime = currentItem.currentTime()
                let currentSeconds = CMTimeGetSeconds(currentTime)
                guard currentSeconds.isFinite && !currentSeconds.isNaN else { return }
                let newSliderValue = Float(currentSeconds)
                if abs(self.timeSlider.value - newSliderValue) > 0.1 {
                    self.timeSlider.maximumValue = Float(durationSeconds)
                    self.timeSlider.minimumValue = 0
                    self.timeSlider.value = newSliderValue
                }
                self.currentTimeLabel.text = VGPlayerUtils.getTimeString(from: currentTime)
                self.streamPosition = currentSeconds
            })
    }

    private func removeMediaPlayerObservers() {
        if let timeObserver = mediaTimeObserver {
            player.removeTimeObserver(timeObserver)
            mediaTimeObserver = nil
        }
        if observingMediaPlayer {
            if let currentItem = player.currentItem {
                currentItem.removeObserver(self, forKeyPath: "duration", context: nil)
                currentItem.removeObserver(self, forKeyPath: "status", context: nil)
            }
            player.removeObserver(self, forKeyPath: "timeControlStatus", context: nil)
            observingMediaPlayer = false
        }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }

    func stop() {
        playerState = .stopped
        player.pause()
    }

    func purgeMediaPlayer() {
        playerState = .stopped
        playerLayer.removeFromSuperlayer()
        player.pause()
    }
}
