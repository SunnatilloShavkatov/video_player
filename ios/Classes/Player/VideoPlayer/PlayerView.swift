//
//  PlayerView.swift
//  udevs_video_player
//
//  Created by Sunnatillo Shavkatov on 13/11/22.
//

import AVKit
import AVFoundation
import TinyConstraints
import NVActivityIndicatorView
import MediaPlayer

protocol PlayerViewDelegate: NSObjectProtocol {
    func close(duration: [Int])
    func settingsPressed()
    func episodesButtonPressed()
    func channelsButtonPressed()
    func showPressed()
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
    var playerLayer =  AVPlayerLayer()
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
        view.backgroundColor = Colors.backgroud
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
    private var titleLabelLandacape: TitleLabel = TitleLabel()
    
    private var liveLabel: UILabel = {
        let label = UILabel()
        label.text = "LIVE"
        label.textColor = .red
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.isHidden = true
        return label;
    }()
    
    private var liveCircle: UIView = {
        let circle = UIView(frame: CGRect(x:6,y:5,width: 12, height: 12))
        circle.layer.cornerRadius = (circle.frame.size.width) / 2
        circle.backgroundColor = .red
        let newCircle = UIView()
        newCircle.addSubview(circle)
        newCircle.isHidden = true
        return newCircle
    }()
    
    private lazy var liveStackView: UIStackView = {
        let liveView = UIStackView(arrangedSubviews: [liveCircle, liveLabel])
        liveView.height(20)
        liveView.sizeToFit()
        liveView.axis = .horizontal
        liveView.distribution = .equalSpacing
        return liveView
    }()
    
    var currentTimeLabel: UILabel = {
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
    
    private var seperatorLabel: UILabel = {
        let label = UILabel()
        label.text = " / "
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        return label
    }()
    
    private var timeSlider: UISlider = {
        let slider = UISlider()
        slider.tintColor = Colors.primary
        slider.maximumTrackTintColor = Colors.white50
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        return slider
    }()
    
    private var rotateButton: IconButton = {
        let button = IconButton()
        if let icon = Svg.rotate {
            button.setImage(icon, for: .normal)
        }
        button.imageEdgeInsets = UIEdgeInsets(top: 4,left: 4,bottom: 4,right: 4)
        button.addTarget(self, action: #selector(changeOrientation(_:)), for: .touchUpInside)
        return button
    }()
    
    private var exitButton: IconButton = {
        let button = IconButton()
        if let icon = Svg.exit {
            button.setImage(icon, for: .normal)
        }
        button.addTarget(self, action: #selector(exitButtonPressed(_:)), for: .touchUpInside)
        return button
    }()
    
    private var pipButton: IconButton = {
        let button = IconButton()
        if let icon = Svg.pip {
            button.setImage(icon, for: .normal)
        }
        button.addTarget(self, action: #selector(togglePictureInPictureMode(_ :)), for: .touchUpInside)
        return button
    }()
    
    private var settingsButton: IconButton = {
        let button = IconButton()
        if let icon = Svg.more {
            button.setImage(icon, for: .normal)
        }
        button.addTarget(self, action: #selector(settingPressed(_ :)), for: .touchUpInside)
        return button
    }()
    
    private var shareButton: IconButton = {
        let button = IconButton()
        if let icon = Svg.share {
            button.setImage(icon, for: .normal)
        }
        button.addTarget(self, action: #selector(share(_ :)), for: .touchUpInside)
        return button
    }()
    
    private var playButton: IconButton = {
        let button = IconButton()
        if let icon = Svg.play {
            button.setImage(icon, for: .normal)
        }
        button.imageEdgeInsets = UIEdgeInsets(top: 4,left: 4,bottom: 4,right: 4)
        button.addTarget(self, action: #selector(playButtonPressed(_:)), for: .touchUpInside)
        return button
    }()
    
    private var skipForwardButton: IconButton = {
        let button = IconButton()
        if let icon = Svg.forward {
            button.setImage(icon, for: .normal)
        }
        button.imageEdgeInsets = UIEdgeInsets(top: 4,left: 4,bottom: 4,right: 4)
        button.addTarget(self, action: #selector(skipForwardButtonPressed(_:)), for: .touchUpInside)
        return button
    }()
    
    private var skipBackwardButton: IconButton = {
        let button = IconButton()
        if let icon = Svg.rewind {
            button.setImage(icon, for: .normal)
        }
        button.imageEdgeInsets = UIEdgeInsets(top: 4,left: 4,bottom: 4,right: 4)
        button.addTarget(self, action: #selector(skipBackButtonPressed(_:)), for: .touchUpInside)
        return button
    }()
    
    private var episodesButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        if let icon = Svg.serial {
            button.setImage(icon, for: .normal)
        }
        button.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        button.setTitle("", for: .normal)
        button.layer.zPosition = 3
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13,weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(episodesButtonPressed(_:)), for: .touchUpInside)
        return button
    }()
    
    private var channelsButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        if let icon = Svg.channels {
            button.setImage(icon, for: .normal)
        }
        button.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        button.setTitle("", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(channelsButtonPressed(_:)), for: .touchUpInside)
        return button
    }()
    
    private var showsBtn: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        if let icon = Svg.programmes {
            button.setImage(icon, for: .normal)
        }
        button.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        button.setTitle("", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(showPressed), for: .touchUpInside)
        return button
    }()
    
    private var activityIndicatorView: NVActivityIndicatorView = {
        let activityView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50), type: .circleStrokeSpin, color: .white)
        return activityView
    }()
    
    private var brightnessSlider: UISlider = {
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
    
    private var playerRate : Float = 1.0
    private var enableGesture = true
    private var backwardGestureTimer: Timer?
    private var forwardGestureTimer: Timer?
    private var backwardTouches = 0
    private var forwardTouches = 0
    
    func setIsPipEnabled(v:Bool){
        pipButton.isEnabled = v
    }
    
    func isHiddenPiP(isPiP: Bool){
        overlayView.isHidden = isPiP
    }
    
    func loadMedia(autoPlay: Bool, playPosition: TimeInterval, area:UILayoutGuide) {
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
    
    private func uiSetup(){
        configureVolume()
        episodesButton.setTitle(" "+playerConfiguration.episodeButtonText, for: .normal)
        showsBtn.setTitle("", for: .normal)
        if playerConfiguration.isLive {
            episodesButton.isHidden = true
        } else {
            showsBtn.isHidden = true
            channelsButton.isHidden = true
        }
        if #available(iOS 13.0, *) {
            setSliderThumbTintColor(Colors.primary)
        } else {
            timeSlider.thumbTintColor = Colors.primary
            brightnessSlider.thumbTintColor = Colors.white
        }
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
    
    fileprivate func makeCircleWithBorder(size: CGSize, backgroundColor: UIColor, borderColor: UIColor, borderWidth: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        // Draw the circle with background color
        context?.setFillColor(backgroundColor.cgColor)
        context?.setStrokeColor(UIColor.clear.cgColor)
        let bounds = CGRect(origin: .zero, size: size)
        context?.addEllipse(in: bounds)
        context?.drawPath(using: .fill)
        
        // Draw the border
        context?.setLineWidth(borderWidth)
        context?.setStrokeColor(borderColor.cgColor)
        context?.addEllipse(in: bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2))
        context?.drawPath(using: .stroke)
        
        // Get the image from the context
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func setSliderThumbTintColor(_ color: UIColor) {
        let circle = makeCircleWith(size: CGSize(width: 4, height: 4),
                                         backgroundColor: UIColor.white)
        brightnessSlider.setThumbImage(circle, for: .normal)
        ///
        let circleImage = makeCircleWithBorder(size: CGSize(width: 24, height: 24),
                                               backgroundColor: color, borderColor: Colors.backgroud, borderWidth: 3)
        timeSlider.setThumbImage(circleImage, for: .normal)
    }
    
    func loadMediaPlayer(asset:AVURLAsset){
        player.automaticallyWaitsToMinimizeStalling = true
        player.replaceCurrentItem(with: AVPlayerItem(asset: asset))
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
        if (playerConfiguration.isLive){
            if (UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight){
                playerLayer.videoGravity = .resize
            } else {
                playerLayer.videoGravity = .resizeAspect
            }
        } else {
            playerLayer.videoGravity = .resizeAspect
        }
        videoView.layer.addSublayer(playerLayer)
        layer.insertSublayer(playerLayer, above: videoView.layer)
        if !playerConfiguration.isLive {
            NotificationCenter.default.addObserver(self, selector: #selector(playerEndedPlaying), name: Notification.Name("AVPlayerItemDidPlayToEndTimeNotification"), object: nil)
        }
        addTimeObserver()
    }
    
    
    func playOfflineAsset() {
        guard let url = URL(string: playerConfiguration.url) else {
            return
        }
        loadMediaPlayer(asset: AVURLAsset(url: url))
    }
    
    func changeUrl(url:String?, title: String?){
        guard let videoURL = URL(string: url ?? "") else {
            return
        }
        self.setTitle(title: title)
        self.player.replaceCurrentItem(with: AVPlayerItem(asset: AVURLAsset(url: videoURL)))
        self.player.seek(to: CMTime.zero)
        self.player.currentItem?.preferredForwardBufferDuration = TimeInterval(1)
        self.player.automaticallyWaitsToMinimizeStalling = true
        self.player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
    }
    
    func changeQuality(url:String?){
        if(url == nil){ return}
        guard let bitrate = Double(url!) else {
            self.player.currentItem?.preferredPeakBitRate = 5687102
            return
        }
        self.player.currentItem?.preferredPeakBitRate = bitrate
    }
    
    func setSubtitleCurrentItem() -> [String]{
        var subtitles = player.currentItem?.tracks(type: .subtitle) ?? ["None"]
        subtitles.insert("None", at: 0)
        return subtitles
    }
    
    func getSubtitleTrackIsEmpty(selectedSubtitleLabel: String) -> Bool{
        return (player.currentItem?.select(type: .subtitle, name: selectedSubtitleLabel)) != nil
    }
    
    func changeSpeed(rate: Float){
        self.playerRate = rate
        self.player.preroll(atRate: self.playerRate, completionHandler: nil)
        self.player.rate = Float(self.playerRate)
    }
    
    func setTitle(title: String?){
        self.titleLabelPortrait.isHidden = false
        self.titleLabelPortrait.text = title ?? ""
        self.titleLabelLandacape.text = title ?? ""
    }
    
    @objc func exitButtonPressed(_ sender: UIButton){
        purgeMediaPlayer();
        removeMediaPlayerObservers();
        delegate?.close(duration: [Int(player.currentTime().seconds),
            Int(player.currentItem!.duration.seconds)]
        )
    }
    
    @objc func togglePictureInPictureMode(_ sender: UIButton){
        delegate?.togglePictureInPictureMode()
    }
    
    @objc func settingPressed(_ sender: UIButton){
        delegate?.settingsPressed()
    }
    
    @objc func share(_ sender : UIButton){
        delegate?.share()
    }
    
    @objc func changeOrientation(_ sender: UIButton){
        delegate?.changeOrientation()
    }
    
    @objc func episodesButtonPressed(_ sender: UIButton){
        delegate?.episodesButtonPressed()
    }
    
    @objc func channelsButtonPressed(_ sender: UIButton){
       delegate?.channelsButtonPressed()
   }
    
    @objc func showPressed(_ sender: UIButton){
        delegate?.showPressed()
    }
    
    @objc func skipBackButtonPressed(_ sender: UIButton){
            self.backwardTouches += 1
            self.seekBackwardTo(10.0 * Double(self.backwardTouches))
            self.backwardGestureTimer?.invalidate()
            self.backwardGestureTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                self.backwardTouches = 0
            }
            resetTimer()
    }
    
    @objc func skipForwardButtonPressed(_ sender: UIButton){
            self.forwardTouches += 1
            self.seekForwardTo(10.0 * Double(self.forwardTouches))
            self.forwardGestureTimer?.invalidate()
            self.forwardGestureTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                self.forwardTouches = 0
            }
            resetTimer()
    }
    
    @objc func playButtonPressed(_ sender: UIButton){
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
        UIView.animate(withDuration: 0.3, delay: 0.2, options: options, animations: {[self] in
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
            UIView.animate(withDuration: 0.1, delay: 0.1, options: options, animations: {[self] in
                let alpha = 0.0
                skipForwardButton.alpha = alpha
            }, completion: nil)
        }
    }
    
    @objc func hideSeekBackwardButton() {
        if topView.alpha == 0 {
            let options: UIView.AnimationOptions = [.curveEaseIn]
            UIView.animate(withDuration: 0.1, delay: 0.1, options: options, animations: {[self] in
                let alpha = 0.0
                skipBackwardButton.alpha = alpha
            }, completion: nil)
        }
    }
    
    func showControls() {
        let options: UIView.AnimationOptions = [.curveEaseIn]
        UIView.animate(withDuration: 0.3, delay: 0.2, options: options, animations: {[self] in
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
    
    func resetTimer() {
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
                if playerConfiguration.isLive {
                    self.playerLayer.videoGravity = .resize
                } else {
                    self.playerLayer.videoGravity = .resizeAspect
                }
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
    
    func fullFrame() -> CGRect {
        return bounds
    }
    
    override func updateConstraints() {
        super.updateConstraints()
    }
    
    func changeConstraints(){
        if UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight {
            addVideoPortaitConstraints()
        } else {
            addVideoLandscapeConstraints()
        }
    }
    
    private func addVideoPortaitConstraints() {
        titleLabelLandacape.isHidden = false
        titleLabelPortrait.isHidden = true
    }
    
    private func addVideoLandscapeConstraints() {
        self.playerLayer.videoGravity = .resizeAspect
        titleLabelLandacape.isHidden = true
        titleLabelPortrait.isHidden = false
    }
    
    func addGestures(){
        swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(swipePan))
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureControls))
        addGestureRecognizer(swipeGesture)
        addGestureRecognizer(tapGesture)
    }
    
    func addSubviews() {
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
    func addBottomViewSubviews() {
        bottomView.addSubview(currentTimeLabel)
        bottomView.addSubview(durationTimeLabel)
        bottomView.addSubview(seperatorLabel)
        bottomView.addSubview(timeSlider)
        bottomView.addSubview(episodesButton)
        bottomView.addSubview(channelsButton)
        bottomView.addSubview(showsBtn)
        bottomView.addSubview(rotateButton)
        bottomView.addSubview(liveStackView)
    }
    
    func addTopViewSubviews() {
        topView.addSubview(exitButton)
        topView.addSubview(titleLabelLandacape)
        topView.addSubview(settingsButton)
        topView.addSubview(shareButton)
        topView.addSubview(pipButton)
    }
    
    func addConstraints(area:UILayoutGuide) {
        addBottomViewConstraints(area: area)
        addTopViewConstraints(area: area)
        addControlButtonConstraints()
    }
    
    private func addControlButtonConstraints(){
        
        ///
        brightnessSlider.centerY(to: overlayView)
        brightnessSlider.width(120)
        brightnessSlider.height(12)
        
        brightnessSlider.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(-42)
        }
        ///
        playButton.centerX(to: overlayView)
        playButton.centerY(to: overlayView)
        playButton.width(Constants.controlButtonSize)
        playButton.height(Constants.controlButtonSize)
        
        skipBackwardButton.width(Constants.controlButtonSize)
        skipBackwardButton.height(Constants.controlButtonSize)
        skipBackwardButton.rightToLeft(of: playButton, offset: -60)
        skipBackwardButton.top(to: playButton)
        
        skipForwardButton.width(Constants.controlButtonSize)
        skipForwardButton.height(Constants.controlButtonSize)
        skipForwardButton.leftToRight(of: playButton, offset: 60)
        skipForwardButton.top(to: playButton)
        
        activityIndicatorView.centerX(to: overlayView)
        activityIndicatorView.centerY(to: overlayView)
        activityIndicatorView.layer.cornerRadius = 20
        if playerConfiguration.isLive {
            skipForwardButton.isHidden = true
            skipBackwardButton.isHidden = true
        }
    }
    
    private func addBottomViewConstraints(area:UILayoutGuide) {
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        bottomView.trailing(to: area, offset: 0)
        bottomView.leading(to: area, offset: 0)
        bottomView.bottom(to: area, offset: 0)
        
        bottomView.height(82)
        
        timeSlider.bottom(to: bottomView, offset: -8)
        timeSlider.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
        }
        
        rotateButton.bottomToTop(of: timeSlider, offset: 8)
        rotateButton.snp.makeConstraints { make in
            make.right.equalTo(bottomView).offset(0)
        }
        
        currentTimeLabel.snp.makeConstraints { make in
            make.left.equalTo(bottomView).offset(8)
        }
        currentTimeLabel.centerY(to: rotateButton)
        
        seperatorLabel.leftToRight(of: currentTimeLabel)
        seperatorLabel.centerY(to: currentTimeLabel)
        channelsButton.rightToLeft(of: rotateButton, offset: -8)
        channelsButton.centerY(to: rotateButton)
        
        durationTimeLabel.leftToRight(of: seperatorLabel)
        durationTimeLabel.centerY(to: seperatorLabel)
        
        
        episodesButton.rightToLeft(of: rotateButton, offset: -8)
        episodesButton.centerY(to: rotateButton)
        
        showsBtn.rightToLeft(of: channelsButton, offset: -16)
        showsBtn.centerY(to: channelsButton)
        
        liveStackView.bottomToTop(of: timeSlider)
        liveStackView.spacing = 24
        liveStackView.leftToSuperview(offset: 2)
        liveStackView.centerY(to: rotateButton)
        
        if !playerConfiguration.isSerial {
            episodesButton.isHidden = true
        }
        
        if playerConfiguration.isLive {
            liveCircle.isHidden = false
            liveLabel.isHidden = false
            currentTimeLabel.isHidden = true
            durationTimeLabel.isHidden = true
            seperatorLabel.isHidden = true
        }
    }
    
    private func addTopViewConstraints(area:UILayoutGuide) {
        topView.leading(to: area, offset: 0)
        topView.trailing(to: area, offset: 0)
        topView.top(to: area, offset: 0)
        topView.height(48)
        
        exitButton.left(to: topView)
        exitButton.centerY(to: topView)
        //
        settingsButton.right(to: topView)
        settingsButton.centerY(to: topView)
        if (playerConfiguration.isLive) {
            shareButton.isHidden = true
        } else {
            shareButton.isHidden = false
            shareButton.rightToLeft(of: settingsButton)
            shareButton.centerY(to: topView)
        }
        
        pipButton.leftToRight(of: exitButton)
        pipButton.centerY(to: topView)
        
        titleLabelLandacape.centerY(to: topView)
        titleLabelLandacape.centerX(to: topView)
        titleLabelLandacape.leftToRight(of: pipButton)
        titleLabelLandacape.layoutMargins = .horizontal(8)
        titleLabelPortrait.centerX(to: overlayView)
        titleLabelPortrait.topToBottom(of: topView, offset: 8)
        titleLabelPortrait.layoutMargins = .horizontal(24)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "duration", let duration = player.currentItem?.duration.seconds, duration > 0.0 {
            self.durationTimeLabel.text = VGPlayerUtils.getTimeString(from: player.currentItem!.duration)
        }
        if keyPath == "status" {
            if player.status == .readyToPlay {
                handleMediaPlayerReady()
            } else if player.status == .readyToPlay {
                
            }
        }
        if keyPath == "timeControlStatus", let change = change, let newValue = change[NSKeyValueChangeKey.newKey] as? Int, let oldValue = change[NSKeyValueChangeKey.oldKey] as? Int {
            if newValue != oldValue {
                DispatchQueue.main.async {[weak self] in
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
            if player.timeControlStatus == .paused {
                // Player is paused
            }
        }
    }
    
    func handleMediaPlayerReady() {
//        print("handleMediaPlayerReady \(pendingPlay)")
        if(!playerConfiguration.isLive){
            if let duration = player.currentItem?.duration, CMTIME_IS_INDEFINITE(duration) {
                purgeMediaPlayer()
                playOfflineAsset()
                return
            }
            if streamDuration == nil  {
                if let duration = player.currentItem?.duration {
                    streamDuration = CMTimeGetSeconds(duration)
                    if let streamDuration = streamDuration {
                        timeSlider.maximumValue = Float(streamDuration)
                        timeSlider.minimumValue = 0
                        timeSlider.value = Float(pendingPlayPosition)
                        timeSlider.isEnabled = true
                    }
                }
            }
        }
        if !pendingPlayPosition.isNaN, pendingPlayPosition > 0 {
            player.seek(to: CMTimeMakeWithSeconds(pendingPlayPosition, preferredTimescale: 1)) { [weak self] _ in
                if self?.playerState == .starting {
                    self?.pendingPlay = true
                }
                self?.handleSeekFinished()
            }
            return
        } else {
            activityIndicatorView.stopAnimating()
        }
        if pendingPlay {
            pendingPlay = false
            player.play()
            playerState = .playing
        } else {
            playerState = .paused
        }
    }
    
    func handleSeekFinished() {
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
    
    func setPlayButton(isPlay: Bool){
        if isPlay {
            playButton.setImage(Svg.pause!, for: .normal)
        } else {
            playButton.setImage(Svg.play!, for: .normal)
        }
    }
    
    func setDuration(position: Float){
        timeSlider.value = position
        currentTimeLabel.text = VGPlayerUtils.getTimeString(from : CMTimeMake(value: Int64(position), timescale: 1))
    }
    
    @objc func playerEndedPlaying(_ notification: Notification) {
        DispatchQueue.main.async {[weak self] in
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
    
    func verticalMoved(_ value: CGFloat) {
        if isVolume {
            self.volumeViewSlider.value -= Float(value / 10000)
        } else {
            brightnessSlider.isHidden = false
            brightnessSlider.value -= Float(value / 10000)
            UIScreen.main.brightness -= value / 10000
        }
    }
    
    func showBlockControls(){
        let options: UIView.AnimationOptions = [.curveEaseIn]
        UIView.animate(withDuration: 0.3, delay: 0.2, options: options, animations: {[self] in
            let alpha = 1.0
            topView.alpha = alpha
            resetTimer()
        }, completion: nil)
    }
    
    
    func toggleViews() {
        let options: UIView.AnimationOptions = [.curveEaseIn]
        UIView.animate(withDuration: 0.05, delay: 0, options: options, animations: {[self] in
            let alpha = topView.alpha == 0.0 ? 1.0 : 0.0
            topView.alpha = alpha
            overlayView.alpha = alpha
            skipForwardButton.alpha = alpha
            skipBackwardButton.alpha = alpha
            if enableGesture {
                playButton.alpha = alpha
            }
            bottomView.alpha = alpha
            if(alpha == 1.0){
                resetTimer()
            }
        }, completion: nil)
    }
    
    func fastForward() {
        self.forwardTouches += 1
        if forwardTouches < 2{
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
    
    func fastBackward() {
        self.backwardTouches += 1
        if backwardTouches < 2{
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
    
    func resetSeekForwardTimer() {
        seekForwardTimer?.invalidate()
        seekForwardTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(hideSeekForwardButton), userInfo: nil, repeats: false)
    }
    
    func resetSeekBackwardTimer() {
        seekBackwardTimer?.invalidate()
        seekBackwardTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(hideSeekBackwardButton), userInfo: nil, repeats: false)
    }
    
    func showSeekForwardButton(){
        skipForwardButton.alpha = 1.0
    }
    func showSeekBackwardButton(){
        skipBackwardButton.alpha = 1.0
    }
    
    @objc func hideBlockControls() {
        let options: UIView.AnimationOptions = [.curveEaseIn]
        UIView.animate(withDuration: 0.3, delay: 0.2, options: options, animations: {[self] in
            _ = 0.0
        }, completion: nil)
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
        guard let duration = player.currentItem?.duration else {return}
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime + seekPosition
        if newTime < (CMTimeGetSeconds(duration) - seekPosition) {
            let time: CMTime = CMTimeMake(value: Int64(newTime*1000), timescale: 1000)
            player.seek(to: time)
        }
    }
    
    fileprivate func seekBackwardTo(_ seekPosition: Double) {
        let currentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = currentTime - seekPosition
        if newTime < 0 {
            newTime = 0
        }
        let time: CMTime = CMTimeMake(value: Int64(newTime*1000), timescale: 1000)
        player.seek(to: time)
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {
        player.seek(to: CMTimeMake(value: Int64(sender.value*1000), timescale: 1000))
    }
    
    @objc func playerDidFinishPlaying() {
        purgeMediaPlayer();
        removeMediaPlayerObservers();
        delegate?.close(duration: [Int(player.currentTime().seconds),
            Int(player.currentItem!.duration.seconds)]
        )
    }
    
    /// MARK: - Time logic
    func addTimeObserver() {
        NotificationCenter.default.addObserver(self,
                                           selector: #selector(playerDidFinishPlaying),
                                           name: .AVPlayerItemDidPlayToEndTime,
                                           object: player.currentItem)
        player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
        player.currentItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        player.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        if(!playerConfiguration.isLive){
            let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            let mainQueue = DispatchQueue.main
            player.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue, using: { [weak self] time in
                guard let currentItem = self?.player.currentItem else {return}
                
                guard currentItem.duration >= .zero, !currentItem.duration.seconds.isNaN else {
                    return
                }
                self?.timeSlider.maximumValue = Float(currentItem.duration.seconds)
                self?.timeSlider.minimumValue = 0
                self?.timeSlider.value = Float(currentItem.currentTime().seconds)
                self?.currentTimeLabel.text = VGPlayerUtils.getTimeString(from: currentItem.currentTime())
                self?.streamPosition = CMTimeGetSeconds(time)
            })
        } else {
            self.timeSlider.value = 1
        }
    }
    
    func removeMediaPlayerObservers() {
        NotificationCenter.default.removeObserver(self,
                                           name: .AVPlayerItemDidPlayToEndTime,
                                           object: player.currentItem)
        if observingMediaPlayer {
            if let mediaTimeObserverToRemove = mediaTimeObserver {
                player.removeTimeObserver(mediaTimeObserverToRemove)
                mediaTimeObserver = nil
            }
            if player.currentItem != nil {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                          object: player.currentItem)
            }
            player.currentItem?.removeObserver(self, forKeyPath: "duration")
            player.currentItem?.removeObserver(self, forKeyPath: "timeControlStatus")
            player.currentItem?.removeObserver(self, forKeyPath: "status")
            observingMediaPlayer = false
        }
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
