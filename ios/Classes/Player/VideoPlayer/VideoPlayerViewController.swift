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
    
    ///
    weak var delegate: VideoPlayerDelegate?
    private var url: String?
    private var screenProtectorKit: ScreenProtectorKit?
    var qualityLabelText = ""
    var speedLabelText = ""
    var qualityDelegate: QualityDelegate!
    var speedDelegate: SpeedDelegate!
    var subtitleDelegate: SubtitleDelegate!
    var playerConfiguration: PlayerConfiguration!
    private var availableQualities: [QualityVariant] = []
    private var playerRate: Float = 1.0
    private var selectedSpeedText = "1.0x"
    var selectedQualityText = "Auto"
    private var selectedSubtitle = "None"
    
    private lazy var playerView: PlayerView = {
        return PlayerView()
    }()
    
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
        if playerConfiguration.enableScreenProtection {
            if let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) {
                screenProtectorKit = ScreenProtectorKit(window: window)
                screenProtectorKit?.configurePreventionScreenshot()
                screenProtectorKit?.enabledPreventScreenshot()
            }
        }

        // Parse HLS master playlist to get quality variants
        loadQualityVariants()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        playerView.loadMedia(autoPlay: true, playPosition: TimeInterval(playerConfiguration.lastPosition), area: view.safeAreaLayoutGuide)
        setupPictureInPicture()
        super.viewWillAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pipPossibleObservation?.invalidate()
        pipPossibleObservation = nil
        NotificationCenter.default.removeObserver(self)
    }

    deinit {
        pipPossibleObservation?.invalidate()
        pipPossibleObservation = nil
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
        screenProtectorKit?.disablePreventScreenshot()
        if UIDevice.current.userInterfaceIdiom != .pad {
            if let orientation = self.view.window?.windowScene?.interfaceOrientation,
               orientation.isLandscape {
                changeOrientation()
            }
        }
        self.dismiss(animated: true, completion: nil)
        delegate?.getDuration(duration: duration)
    }
    
    func share() {
        if let link = NSURL(string: playerConfiguration.movieShareLink) {
            let objectsToShare = [link] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList]
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    func changeOrientation() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let orientation = windowScene.interfaceOrientation
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
                ) { _ in }
            } else {
                UIDevice.current.setValue(value, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }
    
    func settingsPressed() {
        let vc = SettingVC()
        vc.modalPresentationStyle = .custom
        vc.delegate = self
        vc.speedDelegate = self
        vc.subtitleDelegate = self
        var settingModels: [SettingModel] = []

        if let settingsIcon = Svg.settings {
            settingModels.append(SettingModel(leftIcon: settingsIcon, title: qualityLabelText, configureLabel: selectedQualityText))
        }

        if let playSpeedIcon = Svg.playSpeed {
            settingModels.append(SettingModel(leftIcon: playSpeedIcon, title: speedLabelText, configureLabel: selectedSpeedText))
        }

        vc.settingModel = settingModels
        self.present(vc, animated: true, completion: nil)
    }
    
    func togglePictureInPictureMode() {
        guard let pipController else { return }
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
    
    // settings bottom sheet tapped
    func onSettingsBottomSheetCellTapped(index: Int) {
        switch index {
        case 0:
            showQualityBottomSheet()
            break
        case 1:
            showSpeedBottomSheet()
            break
        case 2:
            showSubtitleBottomSheet()
            break
        case 3:
            break
        default:
            break
        }
    }
    
    // bottom sheet tapped
    func onBottomSheetCellTapped(index: Int, type: BottomSheetType) {
        switch type {
        case .quality:
            // Build quality list (same as showQualityBottomSheet)
            var qualities = ["Auto"]
            if !availableQualities.isEmpty {
                qualities.append(contentsOf: availableQualities.map { $0.displayName })
            }
            
            guard index < qualities.count else { return }
            
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
            let selectedSubtitleLabel = subtitles[index]
            if playerView.getSubtitleTrackIsEmpty(selectedSubtitleLabel: selectedSubtitleLabel) {
                selectedSubtitle = selectedSubtitleLabel
            }
            break
        case .audio:
            break
        }
    }
    
    private func showSubtitleBottomSheet() {
        let subtitles = playerView.setSubtitleCurrentItem()
        let bottomSheetVC = BottomSheetViewController()
        bottomSheetVC.modalPresentationStyle = .overCurrentContext
        bottomSheetVC.items = subtitles
        bottomSheetVC.labelText = "Subtitle"
        bottomSheetVC.bottomSheetType = .subtitle
        bottomSheetVC.selectedIndex = subtitles.firstIndex(of: selectedSubtitle) ?? 0
        bottomSheetVC.cellDelegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.present(bottomSheetVC, animated: false, completion: nil)
        }
    }
    
    private func loadQualityVariants() {
        let videoUrl = playerConfiguration.url
        guard !videoUrl.isEmpty else { return }
        
        guard availableQualities.isEmpty else { return }
        
        // Background parsing doesn't affect video playback
        HlsParser.parseHlsMasterPlaylist(url: videoUrl) { [weak self] variants in
            guard let self = self else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if !variants.isEmpty {
                    self.availableQualities = variants
                }
            }
        }
    }
    
    func showQualityBottomSheet() {
        // Build quality list from parsed variants
        var listOfQuality = ["Auto"]
        if !availableQualities.isEmpty {
            listOfQuality.append(contentsOf: availableQualities.map { $0.displayName })
        }
        
        let bottomSheetVC = BottomSheetViewController()
        bottomSheetVC.modalPresentationStyle = .overCurrentContext
        bottomSheetVC.items = listOfQuality
        bottomSheetVC.labelText = qualityLabelText
        bottomSheetVC.cellDelegate = self
        bottomSheetVC.bottomSheetType = .quality
        bottomSheetVC.selectedIndex = listOfQuality.firstIndex(of: selectedQualityText) ?? 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.present(bottomSheetVC, animated: false, completion: nil)
        }
    }
}

extension VideoPlayerViewController: QualityDelegate, SpeedDelegate, SubtitleDelegate {
    func speedBottomSheet() {
        showSpeedBottomSheet()
    }
    
    func qualityBottomSheet() {
        showQualityBottomSheet()
    }
    
    func subtitleBottomSheet() {
        showSubtitleBottomSheet()
    }
}
