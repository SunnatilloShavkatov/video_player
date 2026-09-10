#if os(iOS)
//
//  VideoPlayerViewController.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 23/06/24.
//

import AVFoundation
import AVKit
import MediaPlayer
import SnapKit
import UIKit

class VideoPlayerViewController: UIViewController, AVPictureInPictureControllerDelegate, SettingsBottomSheetCellDelegate, BottomSheetCellDelegate, PlayerViewDelegate {

    private var speedList = ["2.0", "1.5", "1.0", "0.5"].sorted()
    private var pipController: AVPictureInPictureController?
    private var pipPossibleObservation: NSKeyValueObservation?
    private var hasReportedPlaybackResult = false
    private var hasNotifiedDismissal = false
    private var isClosingPlayer = false
    private var dismissalCompletionHandlers: [() -> Void] = []
    private var settingsActions: [SettingAction] = []

    ///
    weak var delegate: VideoPlayerDelegate?
    var onPlaybackFinished: (([Int]) -> Void)?
    var onDidDismiss: (() -> Void)?
    private var url: String?
    private var screenProtectorKit: ScreenProtectorKit?
    var qualityLabelText = ""
    var speedLabelText = ""
    var qualityDelegate: QualityDelegate!
    var speedDelegate: SpeedDelegate!
    var subtitleDelegate: SubtitleDelegate!
    var playerConfiguration: PlayerConfiguration!
    private var availableQualities: [QualityVariant] = []
    private var hlsParseTask: URLSessionDataTask?
    private var playerRate: Float = 1.0
    private var selectedSpeedText = "1.0x"
    var selectedQualityText = "Auto"
    private var selectedSubtitle = "None"
    private var selectedSubtitleSize = "100%"
    private var isSubtitlesEnabled: Bool = true
    private var currentSubtitleTrack: SubtitleTrack?
    private let kSubtitlesEnabled = "video_player_subtitles_enabled"
    private let kSelectedSubtitleLang = "video_player_subtitle_lang"
    private let kSubtitleFontSize = "video_player_subtitle_font_size"
    private let subtitleSizeList = ["50%", "75%", "100%", "150%", "200%", "300%"]

    private lazy var playerView: PlayerView = {
        return PlayerView()
    }()

    private var supportsQualitySelection: Bool {
        !playerConfiguration.playVideoFromAsset && HlsParser.isLikelyHls(url: playerConfiguration.url)
    }

    private var canShareContent: Bool {
        !playerConfiguration.playVideoFromAsset && !playerConfiguration.movieShareLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Subtitle controls exist only for sidecar tracks supplied in the configuration.
    /// A manifest that happens to declare its own text tracks must not surface the
    /// Subtitle rows on its own.
    private var hasSubtitleSelection: Bool {
        !playerConfiguration.subtitles.isEmpty
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupPictureInPicture() {
        if AVPictureInPictureController.isPictureInPictureSupported() {
            guard let controller = AVPictureInPictureController(playerLayer: playerView.playerLayer) else {
                playerView.setIsPipEnabled(v: false)
                return
            }
            pipController = controller
            controller.delegate = self
            pipPossibleObservation = controller.observe(
                \AVPictureInPictureController.isPictureInPicturePossible,
                options: [.initial, .new]
            ) { [weak self] _, change in
                self?.playerView.setIsPipEnabled(v: change.newValue ?? false)
            }
        } else {
            playerView.setIsPipEnabled(v: false)
        }
    }

    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        playerView.isHiddenPiP(isPiP: true)
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        playerView.isHiddenPiP(isPiP: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        url = playerConfiguration.url
        title = playerConfiguration.title
        view.backgroundColor = .black

        playerView.delegate = self
        playerView.playerConfiguration = playerConfiguration
        view.addSubview(playerView)
        playerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Only enable screen protection if explicitly requested
        // This avoids 10-50ms startup jank and fragile layer manipulation

        if !playerConfiguration.isScreenshotEnabled,
           let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })
        {
            screenProtectorKit = ScreenProtectorKit(window: window)
            screenProtectorKit?.configurePreventionScreenshot()
            screenProtectorKit?.enabledPreventScreenshot()
        }

        playerView.setShareEnabled(canShareContent)
        // Parse HLS master playlist to get quality variants
        loadQualityVariants()
    }

    override func viewWillAppear(_ animated: Bool) {
        playerView.loadMedia(autoPlay: true, playPosition: TimeInterval(playerConfiguration.lastPosition), area: view.safeAreaLayoutGuide)
        playerView.setShareEnabled(canShareContent)
        setupPictureInPicture()
        setupInitialSubtitles()
        super.viewWillAppear(animated)
    }

    private func setupInitialSubtitles() {
        let subtitles = playerConfiguration.subtitles
        guard !subtitles.isEmpty else { return }

        let defaults = UserDefaults.standard
        if defaults.object(forKey: kSubtitlesEnabled) != nil {
            isSubtitlesEnabled = defaults.bool(forKey: kSubtitlesEnabled)
        } else {
            isSubtitlesEnabled = true
        }

        let savedLang = defaults.string(forKey: kSelectedSubtitleLang)
        let defaultSub = subtitles.first(where: { $0.isDefault }) ?? subtitles.first
        let matchingSub: SubtitleTrack?
        if let savedLang = savedLang, let found = subtitles.first(where: { $0.lang == savedLang }) {
            matchingSub = found
        } else {
            matchingSub = defaultSub
        }

        let savedFontSize = defaults.integer(forKey: kSubtitleFontSize)
        let fontSizePercent = savedFontSize > 0 ? savedFontSize : 100
        selectedSubtitleSize = "\(fontSizePercent)%"
        playerView.setSubtitleFontSizePercent(fontSizePercent)

        currentSubtitleTrack = matchingSub
        selectedSubtitle = (isSubtitlesEnabled && matchingSub != nil) ? matchingSub!.label : playerConfiguration.subtitleOffText
        playerView.setSubtitleButtonEnabled(isSubtitlesEnabled)
        if isSubtitlesEnabled && matchingSub != nil {
            playerView.loadSubtitleTrack(matchingSub)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isBeingDismissed || navigationController?.isBeingDismissed == true {
            reportPlaybackResultIfNeeded(currentPlaybackPayload())
            notifyDismissalIfNeeded()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pipPossibleObservation?.invalidate()
        pipPossibleObservation = nil
        NotificationCenter.default.removeObserver(self)
    }

    deinit {
        hlsParseTask?.cancel()
        hlsParseTask = nil
        pipPossibleObservation?.invalidate()
        pipPossibleObservation = nil
        screenProtectorKit?.disablePreventScreenshot()
        screenProtectorKit = nil
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        playerView.changeConstraints()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var childForHomeIndicatorAutoHidden: UIViewController? {
        return nil
    }

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.bottom]
    }


    func close(duration: [Int]) {
        requestClose(duration: duration) { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    func share() {
        guard let url = URL(string: playerConfiguration.movieShareLink) else {
            return
        }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityVC, animated: true)
    }

    func changeOrientation() {
        if #available(iOS 16.0, *) {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let orientation = windowScene?.interfaceOrientation
            if orientation == .portrait {
                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
            } else {
                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        } else {
            let orientation = UIDevice.current.orientation
            var value = UIInterfaceOrientation.landscapeRight.rawValue
            if orientation == .landscapeLeft || orientation == .landscapeRight {
                value = UIInterfaceOrientation.portrait.rawValue
            }
            if #available(iOS 16.0, *) {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    return
                }
                self.setNeedsUpdateOfSupportedInterfaceOrientations()
                windowScene.requestGeometryUpdate(
                    .iOS(
                        interfaceOrientations: (orientation == .landscapeLeft || orientation == .landscapeRight)
                            ? .portrait : .landscapeRight)
                ) { _ in
                }
            } else {
                UIDevice.current.setValue(value, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }

    func settingsPressed() {
        let settingModels = buildSettingModels()
        guard !settingModels.isEmpty else { return }

        settingsActions = settingModels.map(\.action)
        let vc = SettingVC()
        vc.modalPresentationStyle = .custom
        vc.delegate = self
        vc.speedDelegate = self
        vc.subtitleDelegate = self
        vc.subtitleSizeDelegate = self
        vc.settingModel = settingModels
        self.present(vc, animated: true, completion: nil)
    }

    func togglePictureInPictureMode() {
        guard let pipController else {
            return
        }
        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else {
            pipController.startPictureInPicture()
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "pip", let pipController {
            if pipController.isPictureInPictureActive {
                playerView.isHiddenPiP(isPiP: true)
            } else {
                playerView.isHiddenPiP(isPiP: false)
            }
        }
    }

    func requestClose(duration: [Int]? = nil, completion: (() -> Void)? = nil) {
        if hasNotifiedDismissal {
            completion?()
            return
        }

        if let completion {
            dismissalCompletionHandlers.append(completion)
        }

        let payload = duration ?? currentPlaybackPayload()
        reportPlaybackResultIfNeeded(payload)

        guard !isClosingPlayer else {
            return
        }

        isClosingPlayer = true
        screenProtectorKit?.disablePreventScreenshot()

        if UIDevice.current.userInterfaceIdiom != .pad,
            let orientation = self.view.window?.windowScene?.interfaceOrientation,
            orientation.isLandscape
        {
            changeOrientation()
        }

        guard presentingViewController != nil || navigationController?.presentingViewController != nil else {
            notifyDismissalIfNeeded()
            return
        }

        dismiss(animated: true) { [weak self] in
            self?.notifyDismissalIfNeeded()
        }
    }

    private func currentPlaybackPayload() -> [Int] {
        let currentSeconds = safeIntFromSeconds(playerView.streamPosition ?? 0)
        let durationSeconds = safeIntFromSeconds(playerView.streamDuration ?? 0)
        return [currentSeconds, durationSeconds]
    }

    private func safeIntFromSeconds(_ seconds: TimeInterval) -> Int {
        guard seconds.isFinite, !seconds.isNaN else { return 0 }
        guard seconds >= Double(Int.min), seconds <= Double(Int.max) else { return 0 }
        return Int(seconds)
    }

    private func reportPlaybackResultIfNeeded(_ payload: [Int]) {
        guard !hasReportedPlaybackResult else { return }
        hasReportedPlaybackResult = true
        onPlaybackFinished?(payload)
        delegate?.getDuration(duration: payload)
    }

    private func notifyDismissalIfNeeded() {
        guard !hasNotifiedDismissal else { return }
        hasNotifiedDismissal = true
        onDidDismiss?()

        let completions = dismissalCompletionHandlers
        dismissalCompletionHandlers.removeAll()
        completions.forEach { $0() }
    }

    // settings bottom sheet tapped
    func onSettingsBottomSheetCellTapped(index: Int) {
        guard index < settingsActions.count else { return }
        dispatchSettingAction(settingsActions[index])
    }

    // bottom sheet tapped
    func onBottomSheetCellTapped(index: Int, type: BottomSheetType) {
        switch type {
        case .quality:
            // Build quality list (same as showQualityBottomSheet)
            var qualities = ["Auto"]
            if !availableQualities.isEmpty {
                qualities.append(
                    contentsOf: availableQualities.map {
                        $0.displayName
                    })
            }

            guard index < qualities.count else {
                return
            }

            self.selectedQualityText = qualities[index]

            // Set quality using preferredPeakBitRate
            if selectedQualityText == "Auto" {
                // Auto mode - adaptive streaming
                playerView.changeQuality(url: "0")
            } else {
                // Find the variant and use its bandwidth
                if let variant = availableQualities.first(where: { $0.displayName == selectedQualityText }) {
                    playerView.changeQuality(url: "\(variant.bandwidth)")
                }
            }
            break
        case .speed:
            self.playerRate = Float(speedList[index])!
            self.selectedSpeedText = "\(self.playerRate)x"
            self.playerView.changeSpeed(rate: self.playerRate)
            break
        case .subtitle:
            let subtitles = playerView.setSubtitleCurrentItem()
            guard index < subtitles.count else { return }
            if !playerConfiguration.subtitles.isEmpty {
                if index == 0 {
                    isSubtitlesEnabled = false
                    UserDefaults.standard.set(false, forKey: kSubtitlesEnabled)
                    selectedSubtitle = playerConfiguration.subtitleOffText
                    playerView.setSubtitleButtonEnabled(false)
                    playerView.loadSubtitleTrack(nil)
                } else {
                    let track = playerConfiguration.subtitles[index - 1]
                    isSubtitlesEnabled = true
                    UserDefaults.standard.set(true, forKey: kSubtitlesEnabled)
                    UserDefaults.standard.set(track.lang, forKey: kSelectedSubtitleLang)
                    currentSubtitleTrack = track
                    selectedSubtitle = track.label
                    playerView.setSubtitleButtonEnabled(true)
                    playerView.loadSubtitleTrack(track)
                }
            } else {
                let selectedSubtitleLabel = subtitles[index]
                if playerView.getSubtitleTrackIsEmpty(selectedSubtitleLabel: selectedSubtitleLabel) {
                    selectedSubtitle = selectedSubtitleLabel
                }
            }
            break
        case .subtitleSize:
            guard index < subtitleSizeList.count else { return }
            let sizeText = subtitleSizeList[index]
            selectedSubtitleSize = sizeText
            let percent = Int(sizeText.replacingOccurrences(of: "%", with: "")) ?? 100
            UserDefaults.standard.set(percent, forKey: kSubtitleFontSize)
            playerView.setSubtitleFontSizePercent(percent)
            break
        case .audio:
            break
        }
    }

    func showSubtitleBottomSheet() {
        guard hasSubtitleSelection else { return }
        let subtitles = playerView.setSubtitleCurrentItem()
        let bottomSheetVC = BottomSheetViewController()
        bottomSheetVC.modalPresentationStyle = .overCurrentContext
        bottomSheetVC.items = subtitles
        bottomSheetVC.labelText = playerConfiguration.subtitleText
        bottomSheetVC.bottomSheetType = .subtitle
        let activeLabel = isSubtitlesEnabled ? selectedSubtitle : playerConfiguration.subtitleOffText
        bottomSheetVC.selectedIndex = subtitles.firstIndex(of: activeLabel) ?? 0
        bottomSheetVC.cellDelegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, self.view.window != nil else { return }
            self.present(bottomSheetVC, animated: false, completion: nil)
        }
    }

    func showSubtitleSizeBottomSheet() {
        guard hasSubtitleSelection else { return }
        let bottomSheetVC = BottomSheetViewController()
        bottomSheetVC.modalPresentationStyle = .overCurrentContext
        bottomSheetVC.items = subtitleSizeList
        bottomSheetVC.labelText = playerConfiguration.subtitleSizeText
        bottomSheetVC.bottomSheetType = .subtitleSize
        bottomSheetVC.selectedIndex = subtitleSizeList.firstIndex(of: selectedSubtitleSize) ?? 2
        bottomSheetVC.cellDelegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, self.view.window != nil else { return }
            self.present(bottomSheetVC, animated: false, completion: nil)
        }
    }

    private func loadQualityVariants() {
        guard supportsQualitySelection else {
            availableQualities = []
            return
        }

        let videoUrl = playerConfiguration.url
        guard !videoUrl.isEmpty else {
            return
        }

        guard availableQualities.isEmpty else {
            return
        }

        // Background parsing doesn't affect video playback
        hlsParseTask = HlsParser.parseHlsMasterPlaylist(url: videoUrl) { [weak self] variants in
            guard let self = self else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                if !variants.isEmpty {
                    self.availableQualities = variants
                }
            }
        }
    }

    func showQualityBottomSheet() {
        guard supportsQualitySelection else { return }
        // Build quality list from parsed variants
        var listOfQuality = ["Auto"]
        if !availableQualities.isEmpty {
            listOfQuality.append(
                contentsOf: availableQualities.map {
                    $0.displayName
                })
        }

        let bottomSheetVC = BottomSheetViewController()
        bottomSheetVC.modalPresentationStyle = .overCurrentContext
        bottomSheetVC.items = listOfQuality
        bottomSheetVC.labelText = qualityLabelText
        bottomSheetVC.cellDelegate = self
        bottomSheetVC.bottomSheetType = .quality
        bottomSheetVC.selectedIndex = listOfQuality.firstIndex(of: selectedQualityText) ?? 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, self.view.window != nil else { return }
            self.present(bottomSheetVC, animated: false, completion: nil)
        }
    }

    func showSpeedBottomSheet() {
        let bottomSheetVC = BottomSheetViewController()
        bottomSheetVC.modalPresentationStyle = .custom
        bottomSheetVC.items = speedList
        bottomSheetVC.labelText = speedLabelText
        bottomSheetVC.cellDelegate = self
        bottomSheetVC.bottomSheetType = .speed
        bottomSheetVC.selectedIndex = speedList.firstIndex(of: "\(self.playerRate)") ?? 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, self.view.window != nil else { return }
            self.present(bottomSheetVC, animated: false, completion: nil)
        }
    }

    private func buildSettingModels() -> [SettingModel] {
        var models: [SettingModel] = []

        if supportsQualitySelection, let qualityIcon = Svg.settings {
            models.append(
                SettingModel(
                    leftIcon: qualityIcon,
                    title: qualityLabelText,
                    configureLabel: selectedQualityText,
                    action: .quality
                )
            )
        }

        if let playSpeedIcon = Svg.playSpeed {
            models.append(
                SettingModel(
                    leftIcon: playSpeedIcon,
                    title: speedLabelText,
                    configureLabel: selectedSpeedText,
                    action: .speed
                )
            )
        }

        if hasSubtitleSelection {
            let subtitleIcon = Svg.ccIcon(enabled: isSubtitlesEnabled) ?? UIImage()
            let subDisplay = isSubtitlesEnabled ? selectedSubtitle : playerConfiguration.subtitleOffText
            models.append(
                SettingModel(
                    leftIcon: subtitleIcon,
                    title: playerConfiguration.subtitleText,
                    configureLabel: subDisplay,
                    action: .subtitle
                )
            )
            let textSizeIcon = UIImage(systemName: "textformat.size")?
                .withTintColor(.white, renderingMode: .alwaysOriginal) ?? Svg.settings ?? UIImage()
            models.append(
                SettingModel(
                    leftIcon: textSizeIcon,
                    title: playerConfiguration.subtitleSizeText,
                    configureLabel: selectedSubtitleSize,
                    action: .subtitleSize
                )
            )
        }

        return models
    }

    private func dispatchSettingAction(_ action: SettingAction) {
        switch action {
        case .quality:
            showQualityBottomSheet()
        case .speed:
            showSpeedBottomSheet()
        case .subtitle:
            showSubtitleBottomSheet()
        case .subtitleSize:
            showSubtitleSizeBottomSheet()
        }
    }
}

extension VideoPlayerViewController: QualityDelegate, SpeedDelegate, SubtitleDelegate, SubtitleSizeDelegate {
    func speedBottomSheet() {
        showSpeedBottomSheet()
    }

    func qualityBottomSheet() {
        showQualityBottomSheet()
    }

    func subtitleBottomSheet() {
        showSubtitleBottomSheet()
    }

    func subtitleSizeBottomSheet() {
        showSubtitleSizeBottomSheet()
    }
}

#endif
