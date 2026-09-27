//
//  PlayerControlsView.swift
//  video_player
//
//  Full-screen macOS controls: top bar (back, title, share, settings), center
//  (rewind, play/pause, forward, spinner) and bottom bar (time, slider, fullscreen).
//  Hierarchy, layout and display state only; VideoPlayerOverlayView wires the
//  actions and owns playback.
//

#if os(macOS)
import AppKit

final class PlayerControlsView: NSView {

    // MARK: - Controls (actions are wired by the owner)

    let backButton = NSButton()
    let shareButton = NSButton()
    let settingsButton = NSButton()
    let rewindButton = NSButton()
    let playPauseButton = NSButton()
    let forwardButton = NSButton()
    let timeSlider = NSSlider()
    let fullscreenButton = NSButton()

    // MARK: - Layout

    private let topBar = NSView()
    private let bottomBar = NSView()
    private let centerControls = NSStackView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let topActionStack = NSStackView()
    private let loadingIndicator = NSProgressIndicator()
    private let currentTimeLabel = NSTextField(labelWithString: "00:00")
    private let durationTimeLabel = NSTextField(labelWithString: "00:00")

    init(title: String, showsShare: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true

        setupTopBar(title: title, showsShare: showsShare)
        setupCenterControls()
        setupBottomBar()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        autoHideTimer?.invalidate()
    }

    // MARK: - Display State

    func setPlaying(_ isPlaying: Bool) {
        playPauseButton.image = isPlaying ? Svg.pause : Svg.play
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimation(nil)
        } else {
            loadingIndicator.stopAnimation(nil)
        }
    }

    func setCurrentTime(_ seconds: Double) {
        currentTimeLabel.stringValue = Self.formatTime(seconds: seconds)
    }

    func setDuration(_ seconds: Double) {
        durationTimeLabel.stringValue = Self.formatTime(seconds: seconds)
        timeSlider.maxValue = seconds
    }

    // MARK: - Auto-Hide

    /// Asked when the auto-hide timer fires; return false to keep the controls
    /// up (paused, or the user is dragging the slider).
    var canAutoHide: (() -> Bool)?
    private(set) var isShown = true
    private var autoHideTimer: Timer?

    /// Shows the controls if hidden and restarts the auto-hide countdown.
    func show() {
        if !isShown {
            isShown = true
            setVisible(true)
        }
        scheduleAutoHide()
    }

    func scheduleAutoHide() {
        autoHideTimer?.invalidate()
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { [weak self] _ in
            self?.hideIfAllowed()
        }
    }

    func cancelAutoHide() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }

    private func hideIfAllowed() {
        guard isShown, canAutoHide?() ?? true else { return }
        isShown = false
        setVisible(false)
    }

    /// Fades the whole control layer; showing is quicker than hiding.
    private func setVisible(_ isVisible: Bool) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = isVisible ? 0.25 : 0.35
            self.animator().alphaValue = isVisible ? 1.0 : 0.0
        }
    }

    // MARK: - Speed Menu

    private var onSpeedSelected: ((Float) -> Void)?

    /// Pops the settings menu, with a speed submenu, under the settings button.
    func showSpeedMenu(title: String, currentRate: Float, onSelect: @escaping (Float) -> Void) {
        onSpeedSelected = onSelect
        let menu = NSMenu(title: "Settings")

        let speedMenu = NSMenu(title: "Speed")
        let speeds: [(String, Float)] = [("0.5x", 0.5), ("0.75x", 0.75), ("1.0x", 1.0), ("1.25x", 1.25), ("1.5x", 1.5), ("2.0x", 2.0)]
        for (label, rate) in speeds {
            let item = NSMenuItem(title: label, action: #selector(speedSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = rate
            item.state = (currentRate == rate) ? .on : .off
            speedMenu.addItem(item)
        }

        let speedItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        speedItem.submenu = speedMenu
        menu.addItem(speedItem)

        let point = NSPoint(x: settingsButton.bounds.minX, y: settingsButton.bounds.maxY + 5)
        menu.popUp(positioning: nil, at: point, in: settingsButton)
    }

    @objc private func speedSelected(_ sender: NSMenuItem) {
        if let rate = sender.representedObject as? Float {
            onSpeedSelected?(rate)
        }
    }

    static func formatTime(seconds: Double) -> String {
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

    // MARK: - Setup

    private func configureIconButton(_ button: NSButton, image: NSImage?, toolTip: String, size: CGFloat) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isBordered = false
        button.image = image
        button.imageScaling = .scaleProportionallyDown
        button.toolTip = toolTip
        button.widthAnchor.constraint(equalToConstant: size).isActive = true
        button.heightAnchor.constraint(equalToConstant: size).isActive = true
    }

    private func setupTopBar(title: String, showsShare: Bool) {
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.wantsLayer = true
        topBar.layer?.backgroundColor = NSColor(white: 0.0, alpha: 0.5).cgColor
        addSubview(topBar)

        configureIconButton(backButton, image: Svg.back, toolTip: "Close (Esc)", size: 36)
        topBar.addSubview(backButton)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.stringValue = title
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.lineBreakMode = .byTruncatingTail
        topBar.addSubview(titleLabel)

        topActionStack.translatesAutoresizingMaskIntoConstraints = false
        topActionStack.orientation = .horizontal
        topActionStack.spacing = 16
        topActionStack.alignment = .centerY
        topBar.addSubview(topActionStack)

        if showsShare {
            configureIconButton(shareButton, image: Svg.share, toolTip: "Share Link", size: 32)
            topActionStack.addArrangedSubview(shareButton)
        }
        configureIconButton(settingsButton, image: Svg.settings, toolTip: "Settings & Speed", size: 32)
        topActionStack.addArrangedSubview(settingsButton)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: topAnchor),
            topBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 64),

            backButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

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
        addSubview(centerControls)

        configureIconButton(rewindButton, image: Svg.rewind, toolTip: "Rewind 10s (←)", size: 48)
        configureIconButton(playPauseButton, image: Svg.pause, toolTip: "Play/Pause (Space)", size: 64)
        configureIconButton(forwardButton, image: Svg.forward, toolTip: "Forward 10s (→)", size: 48)
        [rewindButton, playPauseButton, forwardButton].forEach(centerControls.addArrangedSubview)

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.style = .spinning
        loadingIndicator.isDisplayedWhenStopped = false
        addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            centerControls.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerControls.centerYAnchor.constraint(equalTo: centerYAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            loadingIndicator.widthAnchor.constraint(equalToConstant: 48),
            loadingIndicator.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    private func setupBottomBar() {
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.wantsLayer = true
        bottomBar.layer?.backgroundColor = NSColor(white: 0.0, alpha: 0.5).cgColor
        addSubview(bottomBar)

        for label in [currentTimeLabel, durationTimeLabel] {
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
            label.textColor = .white
        }

        timeSlider.translatesAutoresizingMaskIntoConstraints = false
        timeSlider.minValue = 0
        timeSlider.maxValue = 100
        timeSlider.doubleValue = 0
        timeSlider.isContinuous = true

        configureIconButton(fullscreenButton, image: Svg.rotate, toolTip: "Toggle Fullscreen (F)", size: 32)
        [currentTimeLabel, timeSlider, durationTimeLabel, fullscreenButton].forEach(bottomBar.addSubview)

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: bottomAnchor),
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
        ])
    }
}
#endif
