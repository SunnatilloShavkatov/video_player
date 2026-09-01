//
//  VideoPlayerOverlayView.swift
//  video_player
//

import AVFoundation
import AVKit
import AppKit
import Foundation

class VideoPlayerOverlayView: NSView {
    private let player = AVPlayer()
    private var playerLayer: AVPlayerLayer!

    var playerConfiguration: PlayerConfiguration
    var onPlaybackFinished: (([Int]) -> Void)?
    var onDidDismiss: (() -> Void)?

    private var isResolved = false
    private let resolutionQueue = DispatchQueue(label: "uz.shs.video_player.macos_overlay_session")

    // UI Containers
    private let videoContainer = NSView()
    private let controlsOverlay = NSView()
    private let topBar = NSView()
    private let bottomBar = NSView()
    private let centerControls = NSStackView()

    // Top Bar UI
    private let backButton = NSButton()
    private let titleLabel = NSTextField(labelWithString: "")
    private let topActionStack = NSStackView()
    private let shareButton = NSButton()
    private let settingsButton = NSButton()

    // Center Controls UI
    private let rewindButton = NSButton()
    private let playPauseButton = NSButton()
    private let forwardButton = NSButton()
    private let loadingIndicator = NSProgressIndicator()

    // Bottom Bar UI
    private let currentTimeLabel = NSTextField(labelWithString: "00:00")
    private let durationTimeLabel = NSTextField(labelWithString: "00:00")
    private let timeSlider = NSSlider()
    private let fullscreenButton = NSButton()

    // State & Observers
    private var timeObserver: Any?
    private var autoHideTimer: Timer?
    private var isControlsVisible = true
    private var isUserScrubbing = false
    private var totalDuration: Double = 0
    private var currentPlaybackRate: Float = 1.0

    private var trackingArea: NSTrackingArea?

    init(configuration: PlayerConfiguration) {
        self.playerConfiguration = configuration
        super.init(frame: .zero)

        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.black.cgColor

        setupVideoLayer()
        setupUI()
        setupTracking()
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
        controlsOverlay.translatesAutoresizingMaskIntoConstraints = false
        controlsOverlay.wantsLayer = true
        addSubview(controlsOverlay)

        NSLayoutConstraint.activate([
            controlsOverlay.topAnchor.constraint(equalTo: topAnchor),
            controlsOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            controlsOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            controlsOverlay.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        setupTopBar()
        setupCenterControls()
        setupBottomBar()
    }

    private func setupTopBar() {
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.wantsLayer = true
        topBar.layer?.backgroundColor = NSColor(white: 0.0, alpha: 0.5).cgColor
        controlsOverlay.addSubview(topBar)

        // Back Button
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.isBordered = false
        backButton.image = Svg.back
        backButton.imageScaling = .scaleProportionallyDown
        backButton.target = self
        backButton.action = #selector(backClicked)
        backButton.toolTip = "Close (Esc)"
        topBar.addSubview(backButton)

        // Title Label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.stringValue = playerConfiguration.title
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.lineBreakMode = .byTruncatingTail
        topBar.addSubview(titleLabel)

        // Right Action Stack
        topActionStack.translatesAutoresizingMaskIntoConstraints = false
        topActionStack.orientation = .horizontal
        topActionStack.spacing = 16
        topActionStack.alignment = .centerY
        topBar.addSubview(topActionStack)

        if !playerConfiguration.playVideoFromAsset && !playerConfiguration.movieShareLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            shareButton.isBordered = false
            shareButton.image = Svg.share
            shareButton.imageScaling = .scaleProportionallyDown
            shareButton.target = self
            shareButton.action = #selector(shareClicked)
            shareButton.toolTip = "Share Link"
            shareButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
            shareButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
            topActionStack.addArrangedSubview(shareButton)
        }

        // Settings Button
        settingsButton.isBordered = false
        settingsButton.image = Svg.settings
        settingsButton.imageScaling = .scaleProportionallyDown
        settingsButton.target = self
        settingsButton.action = #selector(settingsClicked)
        settingsButton.toolTip = "Settings & Speed"
        settingsButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        settingsButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        topActionStack.addArrangedSubview(settingsButton)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: controlsOverlay.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: controlsOverlay.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: controlsOverlay.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 64),

            backButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: topActionStack.leadingAnchor, constant: -16),

            topActionStack.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            topActionStack.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
        ])
    }

    private func setupCenterControls() {
        centerControls.translatesAutoresizingMaskIntoConstraints = false
        centerControls.orientation = .horizontal
        centerControls.spacing = 40
        centerControls.alignment = .centerY
        centerControls.distribution = .gravityAreas
        controlsOverlay.addSubview(centerControls)

        // Rewind 10s
        rewindButton.isBordered = false
        rewindButton.image = Svg.rewind
        rewindButton.imageScaling = .scaleProportionallyDown
        rewindButton.target = self
        rewindButton.action = #selector(rewindClicked)
        rewindButton.toolTip = "Rewind 10s (←)"
        rewindButton.widthAnchor.constraint(equalToConstant: 48).isActive = true
        rewindButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        centerControls.addArrangedSubview(rewindButton)

        // Play/Pause
        playPauseButton.isBordered = false
        playPauseButton.image = Svg.pause
        playPauseButton.imageScaling = .scaleProportionallyDown
        playPauseButton.target = self
        playPauseButton.action = #selector(playPauseClicked)
        playPauseButton.toolTip = "Play/Pause (Space)"
        playPauseButton.widthAnchor.constraint(equalToConstant: 64).isActive = true
        playPauseButton.heightAnchor.constraint(equalToConstant: 64).isActive = true
        centerControls.addArrangedSubview(playPauseButton)

        // Forward 10s
        forwardButton.isBordered = false
        forwardButton.image = Svg.forward
        forwardButton.imageScaling = .scaleProportionallyDown
        forwardButton.target = self
        forwardButton.action = #selector(forwardClicked)
        forwardButton.toolTip = "Forward 10s (→)"
        forwardButton.widthAnchor.constraint(equalToConstant: 48).isActive = true
        forwardButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        centerControls.addArrangedSubview(forwardButton)

        // Loading Indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.style = .spinning
        loadingIndicator.isDisplayedWhenStopped = false
        controlsOverlay.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            centerControls.centerXAnchor.constraint(equalTo: controlsOverlay.centerXAnchor),
            centerControls.centerYAnchor.constraint(equalTo: controlsOverlay.centerYAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: controlsOverlay.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: controlsOverlay.centerYAnchor),
            loadingIndicator.widthAnchor.constraint(equalToConstant: 48),
            loadingIndicator.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    private func setupBottomBar() {
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.wantsLayer = true
        bottomBar.layer?.backgroundColor = NSColor(white: 0.0, alpha: 0.5).cgColor
        controlsOverlay.addSubview(bottomBar)

        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        currentTimeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        currentTimeLabel.textColor = .white
        bottomBar.addSubview(currentTimeLabel)

        timeSlider.translatesAutoresizingMaskIntoConstraints = false
        timeSlider.minValue = 0
        timeSlider.maxValue = 100
        timeSlider.doubleValue = 0
        timeSlider.isContinuous = true
        timeSlider.target = self
        timeSlider.action = #selector(sliderMoved(_:))
        bottomBar.addSubview(timeSlider)

        durationTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        durationTimeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        durationTimeLabel.textColor = .white
        bottomBar.addSubview(durationTimeLabel)

        fullscreenButton.translatesAutoresizingMaskIntoConstraints = false
        fullscreenButton.isBordered = false
        fullscreenButton.image = Svg.rotate
        fullscreenButton.imageScaling = .scaleProportionallyDown
        fullscreenButton.target = self
        fullscreenButton.action = #selector(toggleFullscreenClicked)
        fullscreenButton.toolTip = "Toggle Fullscreen (F)"
        bottomBar.addSubview(fullscreenButton)

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: controlsOverlay.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: controlsOverlay.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: controlsOverlay.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 64),

            currentTimeLabel.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            currentTimeLabel.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),

            timeSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 12),
            timeSlider.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            timeSlider.trailingAnchor.constraint(equalTo: durationTimeLabel.leadingAnchor, constant: -12),

            durationTimeLabel.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            durationTimeLabel.trailingAnchor.constraint(equalTo: fullscreenButton.leadingAnchor, constant: -16),

            fullscreenButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            fullscreenButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            fullscreenButton.widthAnchor.constraint(equalToConstant: 32),
            fullscreenButton.heightAnchor.constraint(equalToConstant: 32),
        ])
    }

    // MARK: - Playback Handling

    private func setupPlayback() {
        guard let url = URL(string: playerConfiguration.url) else { return }

        loadingIndicator.startAnimation(nil)

        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: playerItem)

        if playerConfiguration.lastPosition > 0 {
            let targetTime = CMTime(seconds: Double(playerConfiguration.lastPosition), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }

        setupObservers(for: playerItem)
        player.play()
        updatePlayPauseButton()
        resetAutoHideTimer()
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
                    durationTimeLabel.stringValue = formatTime(seconds: durSeconds)
                    timeSlider.maxValue = durSeconds
                    loadingIndicator.stopAnimation(nil)
                }
            }
        }

        currentTimeLabel.stringValue = formatTime(seconds: currentSeconds)
        if !isUserScrubbing {
            timeSlider.doubleValue = currentSeconds
        }
    }

    private func formatTime(seconds: Double) -> String {
        if seconds.isNaN || seconds.isInfinite || seconds < 0 { return "00:00" }
        let total = Int(seconds)
        let hrs = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        if hrs > 0 {
            return String(format: "%02d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
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
        resetAutoHideTimer()
    }

    private func updatePlayPauseButton() {
        let isPlaying = player.timeControlStatus == .playing || player.rate > 0
        playPauseButton.image = isPlaying ? Svg.pause : Svg.play
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
        resetAutoHideTimer()
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
        let targetSeconds = sender.doubleValue
        currentTimeLabel.stringValue = formatTime(seconds: targetSeconds)
        resetAutoHideTimer()
    }

    @objc private func toggleFullscreenClicked() {
        window?.toggleFullScreen(nil)
        resetAutoHideTimer()
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
        let menu = NSMenu(title: "Settings")

        let speedMenu = NSMenu(title: "Speed")
        let speeds: [(String, Float)] = [("0.5x", 0.5), ("0.75x", 0.75), ("1.0x", 1.0), ("1.25x", 1.25), ("1.5x", 1.5), ("2.0x", 2.0)]
        for (label, rate) in speeds {
            let item = NSMenuItem(title: label, action: #selector(speedSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = rate
            item.state = (currentPlaybackRate == rate) ? .on : .off
            speedMenu.addItem(item)
        }

        let speedItem = NSMenuItem(title: "Speed: \(playerConfiguration.speedText)", action: nil, keyEquivalent: "")
        speedItem.submenu = speedMenu
        menu.addItem(speedItem)

        let point = NSPoint(x: settingsButton.bounds.minX, y: settingsButton.bounds.maxY + 5)
        menu.popUp(positioning: nil, at: point, in: settingsButton)
    }

    @objc private func speedSelected(_ sender: NSMenuItem) {
        if let rate = sender.representedObject as? Float {
            currentPlaybackRate = rate
            player.rate = rate
            updatePlayPauseButton()
        }
    }

    @objc private func playerItemDidFinish() {
        requestClose()
    }

    // MARK: - Auto-Hide Controls & Mouse Tracking

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
        showControls()
        resetAutoHideTimer()
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        showControls()
        resetAutoHideTimer()
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            window?.toggleFullScreen(nil)
        } else {
            if isControlsVisible {
                playPauseClicked()
            } else {
                showControls()
                resetAutoHideTimer()
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

    private func showControls() {
        guard !isControlsVisible else { return }
        isControlsVisible = true
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            controlsOverlay.animator().alphaValue = 1.0
        }
    }

    private func hideControls() {
        guard isControlsVisible, !isUserScrubbing, player.timeControlStatus == .playing else { return }
        isControlsVisible = false
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            controlsOverlay.animator().alphaValue = 0.0
        }
    }

    private func resetAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { [weak self] _ in
            self?.hideControls()
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
        let shouldResolve = resolutionQueue.sync { () -> Bool in
            guard !isResolved else { return false }
            isResolved = true
            return true
        }

        guard shouldResolve else { return }

        autoHideTimer?.invalidate()
        autoHideTimer = nil

        var lastPositionSeconds = Int(CMTimeGetSeconds(player.currentTime()))
        if lastPositionSeconds < 0 { lastPositionSeconds = 0 }

        var durationSeconds = Int(totalDuration)
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
        DispatchQueue.main.async { [weak self] in
            self?.onPlaybackFinished?(payload)
            self?.onDidDismiss?()
        }
    }

    deinit {
        finishPlaybackIfNeeded()
    }
}
