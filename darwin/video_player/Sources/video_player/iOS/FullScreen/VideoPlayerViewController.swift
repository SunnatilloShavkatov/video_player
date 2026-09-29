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

class VideoPlayerViewController: UIViewController, AVPictureInPictureControllerDelegate, BottomSheetCellDelegate, PlayerViewDelegate {

    var speedList = ["2.0", "1.5", "1.0", "0.5"].sorted()
    private var pipController: AVPictureInPictureController?
    private var pipPossibleObservation: NSKeyValueObservation?
    private var hasReportedPlaybackResult = false
    private var hasNotifiedDismissal = false
    private var isClosingPlayer = false
    private var dismissalCompletionHandlers: [() -> Void] = []

    ///
    weak var delegate: VideoPlayerDelegate?
    var onPlaybackFinished: (([Int]) -> Void)?
    var onDidDismiss: (() -> Void)?
    private var url: String?
    private var screenProtectorKit: ScreenProtectorKit?
    var qualityLabelText = ""
    var speedLabelText = ""
    var subtitleDelegate: SubtitleDelegate!
    var playerConfiguration: PlayerConfiguration!
    var availableQualities: [QualityVariant] = []
    var hlsParseTask: URLSessionDataTask?
    var playerRate: Float = 1.0
    var selectedSpeedText = "1.0x"
    var selectedQualityText = "Auto"
    var selectedSubtitle = "None"
    var selectedSubtitleSize = "100%"
    var isSubtitlesEnabled: Bool = true
    var currentSubtitleTrack: SubtitleTrack?
    let kSubtitlesEnabled = "video_player_subtitles_enabled"
    let kSelectedSubtitleLang = "video_player_subtitle_lang"
    let kSubtitleFontSize = "video_player_subtitle_font_size"
    let subtitleSizeList = ["50%", "75%", "100%", "150%", "200%", "300%"]

    lazy var playerView: PlayerView = {
        return PlayerView()
    }()

    var supportsQualitySelection: Bool {
        !playerConfiguration.playVideoFromAsset && HlsParser.isLikelyHls(url: playerConfiguration.url)
    }

    private var canShareContent: Bool {
        !playerConfiguration.playVideoFromAsset && !playerConfiguration.movieShareLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Subtitle controls exist only for sidecar tracks supplied in the configuration.
    /// A manifest that happens to declare its own text tracks must not surface the
    /// Subtitle rows on its own.
    var hasSubtitleSelection: Bool {
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
}

#endif
