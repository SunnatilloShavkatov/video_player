//
//  VideoPlayerOverlayView.swift
//  video_player
//

#if os(macOS)
import AVFoundation
import AVKit
import AppKit
import Foundation

class VideoPlayerOverlayView: NSView {
    private let player = AVPlayer()
    private var playerLayer: AVPlayerLayer!
    // Retained here: AVAssetResourceLoader holds its delegate weakly.
    private var keyLoader: HlsKeyResourceLoader?

    var playerConfiguration: PlayerConfiguration
    var onPlaybackFinished: (([Int]) -> Void)?
    var onPlaybackFailed: ((String, String) -> Void)?
    var onDidDismiss: (() -> Void)?

    private var _isResolved = false
    private let resolutionQueue = DispatchQueue(label: "uz.plugin.video_player.macos_overlay_session")

    private var isResolved: Bool {
        resolutionQueue.sync { _isResolved }
    }

    private let videoContainer = NSView()
    // Top bar, center controls and bottom bar; actions are wired in bindControlActions()
    private let controls: PlayerControlsView

    // State & Observers
    private var timeObserver: Any?
    private var isUserScrubbing = false
    private var totalDuration: Double = 0
    private var currentPlaybackRate: Float = 1.0

    private var trackingArea: NSTrackingArea?

    init(configuration: PlayerConfiguration) {
        self.playerConfiguration = configuration
        self.controls = PlayerControlsView(
            title: configuration.title,
            showsShare: !configuration.playVideoFromAsset
                && !configuration.movieShareLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        )
        super.init(frame: .zero)

        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.black.cgColor

        setupVideoLayer()
        setupUI()
        setupTracking()
    }

    /// Starts playback. Call it after `onPlaybackFinished`, `onPlaybackFailed` and `onDidDismiss`
    /// are assigned, otherwise an immediate failure would have nowhere to go.
    func start() {
        setupPlayback()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    // MARK: - Setup

    private func setupVideoLayer() {
        videoContainer.translatesAutoresizingMaskIntoConstraints = false
        videoContainer.wantsLayer = true
        videoContainer.layer?.backgroundColor = NSColor.black.cgColor
        addSubview(videoContainer)

        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        videoContainer.layer?.addSublayer(playerLayer)

        NSLayoutConstraint.activate([
            videoContainer.topAnchor.constraint(equalTo: topAnchor),
            videoContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            videoContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            videoContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupUI() {
        addSubview(controls)

        NSLayoutConstraint.activate([
            controls.topAnchor.constraint(equalTo: topAnchor),
            controls.leadingAnchor.constraint(equalTo: leadingAnchor),
            controls.trailingAnchor.constraint(equalTo: trailingAnchor),
            controls.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        bindControlActions()
    }

    private func bindControlActions() {
        let actions: [(NSControl, Selector)] = [
            (controls.backButton, #selector(backClicked)),
            (controls.shareButton, #selector(shareClicked)),
            (controls.settingsButton, #selector(settingsClicked)),
            (controls.rewindButton, #selector(rewindClicked)),
            (controls.playPauseButton, #selector(playPauseClicked)),
            (controls.forwardButton, #selector(forwardClicked)),
            (controls.timeSlider, #selector(sliderMoved(_:))),
            (controls.fullscreenButton, #selector(toggleFullscreenClicked)),
        ]
        for (control, action) in actions {
            control.target = self
            control.action = action
        }
        controls.canAutoHide = { [weak self] in
            guard let self else { return false }
            return !self.isUserScrubbing && self.player.timeControlStatus == .playing
        }
    }

    // MARK: - Playback Handling

    private func setupPlayback() {
        guard let url = URL(string: playerConfiguration.url) else {
            failPlayback(code: "INVALID_URL", message: "Invalid video URL: \(playerConfiguration.url)")
            return
        }

        controls.setLoading(true)

        let (asset, loader) = HlsKeyResourceLoader.makeAsset(url: url, keyHeaders: playerConfiguration.keyRequestHeaders)
        keyLoader = loader
        let playerItem = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: playerItem)

        if playerConfiguration.lastPosition > 0 {
            let targetTime = CMTime(seconds: Double(playerConfiguration.lastPosition), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }

        setupObservers(for: playerItem)
        player.play()
        updatePlayPauseButton()
        controls.scheduleAutoHide()
    }

    private func setupObservers(for item: AVPlayerItem) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, !self.isResolved else { return }
            self.onTimeUpdate(time: time)
        }
    }

    private func onTimeUpdate(time: CMTime) {
        let currentSeconds = CMTimeGetSeconds(time)
        guard currentSeconds.isFinite && !currentSeconds.isNaN else { return }

        if let currentItem = player.currentItem {
            let duration = currentItem.duration
            if duration.isValid && !duration.isIndefinite {
                let durSeconds = CMTimeGetSeconds(duration)
                if durSeconds.isFinite && !durSeconds.isNaN && durSeconds > 0 {
                    totalDuration = durSeconds
                    controls.setDuration(durSeconds)
                    controls.setLoading(false)
                }
            }
        }

        controls.setCurrentTime(currentSeconds)
        if !isUserScrubbing {
            controls.timeSlider.doubleValue = currentSeconds
        }
    }

    // MARK: - User Actions

    @objc private func backClicked() {
        requestClose()
    }

    @objc private func playPauseClicked() {
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
        updatePlayPauseButton()
        controls.scheduleAutoHide()
    }

    private func updatePlayPauseButton() {
        controls.setPlaying(player.timeControlStatus == .playing || player.rate > 0)
    }

    @objc private func rewindClicked() {
        seekBy(seconds: -10)
    }

    @objc private func forwardClicked() {
        seekBy(seconds: 10)
    }

    private func seekBy(seconds: Double) {
        let current = CMTimeGetSeconds(player.currentTime())
        let target = max(0, min(totalDuration > 0 ? totalDuration : Double.greatestFiniteMagnitude, current + seconds))
        let targetTime = CMTime(seconds: target, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        controls.scheduleAutoHide()
    }

    @objc private func sliderMoved(_ sender: NSSlider) {
        if let event = NSApp.currentEvent {
            if event.type == .leftMouseDown {
                isUserScrubbing = true
            } else if event.type == .leftMouseUp {
                isUserScrubbing = false
                let targetTime = CMTime(seconds: sender.doubleValue, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
            }
        }
        controls.setCurrentTime(sender.doubleValue)
        controls.scheduleAutoHide()
    }

    @objc private func toggleFullscreenClicked() {
        window?.toggleFullScreen(nil)
        controls.scheduleAutoHide()
    }

    @objc private func shareClicked() {
        let link = playerConfiguration.movieShareLink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !link.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(link, forType: .string)

        let alert = NSAlert()
        alert.messageText = "Link Copied"
        alert.informativeText = "Movie link copied to clipboard: \(link)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: window ?? NSApp.mainWindow ?? NSWindow())
    }

    @objc private func settingsClicked() {
        controls.showSpeedMenu(title: "Speed: \(playerConfiguration.speedText)", currentRate: currentPlaybackRate) { [weak self] rate in
            guard let self else { return }
            self.currentPlaybackRate = rate
            self.player.rate = rate
            self.updatePlayPauseButton()
        }
    }

    @objc private func playerItemDidFinish() {
        requestClose()
    }

    // MARK: - Mouse & Keyboard (auto-hide lives in PlayerControlsView)

    private func setupTracking() {
        let options: NSTrackingArea.Options = [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        setupTracking()
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        controls.show()
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        controls.show()
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            window?.toggleFullScreen(nil)
        } else {
            if controls.isShown {
                playPauseClicked()
            } else {
                controls.show()
            }
        }
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 49: // Space
            playPauseClicked()
        case 123: // Left Arrow
            rewindClicked()
        case 124: // Right Arrow
            forwardClicked()
        case 53: // Escape
            requestClose()
        case 3: // 'F' key
            toggleFullscreenClicked()
        default:
            super.keyDown(with: event)
        }
    }

    // MARK: - Close and Cleanup

    func requestClose(completion: (() -> Void)? = nil) {
        finishPlaybackIfNeeded()

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            self.animator().alphaValue = 0.0
        }, completionHandler: {
            self.removeFromSuperview()
            completion?()
        })
    }

    private func finishPlaybackIfNeeded() {
        guard claimResolution() else { return }

        controls.cancelAutoHide()

        var lastPositionSeconds = seconds(from: CMTimeGetSeconds(player.currentTime()))
        if lastPositionSeconds < 0 { lastPositionSeconds = 0 }

        var durationSeconds = seconds(from: totalDuration)
        if durationSeconds <= 0 {
            durationSeconds = max(lastPositionSeconds, 1)
        }

        player.pause()
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        player.replaceCurrentItem(with: nil)

        let payload = [lastPositionSeconds, durationSeconds]
        let finished = onPlaybackFinished
        let dismissed = onDidDismiss
        clearCallbacks()

        deliverOnMain {
            finished?(payload)
            dismissed?()
        }
    }

    private func failPlayback(code: String, message: String) {
        guard claimResolution() else { return }

        controls.cancelAutoHide()

        player.pause()
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        player.replaceCurrentItem(with: nil)

        let failed = onPlaybackFailed
        let dismissed = onDidDismiss
        clearCallbacks()

        removeFromSuperview()
        deliverOnMain {
            failed?(code, message)
            dismissed?()
        }
    }

    private func claimResolution() -> Bool {
        resolutionQueue.sync { () -> Bool in
            guard !_isResolved else { return false }
            _isResolved = true
            return true
        }
    }

    private func clearCallbacks() {
        onPlaybackFinished = nil
        onPlaybackFailed = nil
        onDidDismiss = nil
    }

    private func seconds(from value: Double) -> Int {
        guard value.isFinite else { return 0 }
        return Int(value)
    }

    /// Delivers the result without capturing `self`: the resolution also happens from `deinit`,
    /// where a captured reference would be nil once the block ran and the Dart future would hang.
    private func deliverOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    deinit {
        finishPlaybackIfNeeded()
    }
}
#endif
