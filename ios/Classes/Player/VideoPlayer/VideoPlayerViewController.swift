//
//  VideoPlayerViewController.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 23/06/24.
//

import AVFoundation
import AVKit
import MediaPlayer
import NVActivityIndicatorView
import SnapKit
import TinyConstraints
import UIKit
import XLActionController

/* The player state. */
enum PlaybackMode: Int {
    case none = 0
    case local
    case remote
}

enum CastSessionStatus {
    case started
    case resumed
    case ended
    case failedToStart
    case alreadyConnected
}

class VideoPlayerViewController: UIViewController, AVPictureInPictureControllerDelegate, SettingsBottomSheetCellDelegate, BottomSheetCellDelegate, PlayerViewDelegate {    

    private var speedList = ["2.0", "1.5", "1.0", "0.5"].sorted()

    private var pipController: AVPictureInPictureController!
    private var pipPossibleObservation: NSKeyValueObservation?

    /// chrome cast
    private var localPlaybackImplicitlyPaused: Bool = false
    ///
    weak var delegate: VideoPlayerDelegate?
    private var url: String?
    var qualityLabelText = ""
    var speedLabelText = ""
    var subtitleLabelText = "Субтитле"
    var isRegular: Bool = false
    var resolutions: [String: String]?
    var sortedResolutions: [String] = []
    var qualityDelegate: QualityDelegate!
    var speedDelegate: SpeedDelegate!
    var subtitleDelegate: SubtitleDelegate!
    var playerConfiguration: PlayerConfiguration!
    private var isVolume = false
    private var volumeViewSlider: UISlider!
    private var playerRate: Float = 1.0
    private var selectedSpeedText = "1.0x"
    var selectedQualityText = "Auto"
    private var selectedSubtitle = "None"

    private lazy var playerView: PlayerView = {
        return PlayerView()
    }()

    private lazy var screenshotPreventView = ScreenshotPreventingView(contentView: playerView)

    private var portraitConstraints = Constraints()
    private var landscapeConstraints = Constraints()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupPictureInPicture() {
        if AVPictureInPictureController.isPictureInPictureSupported() {
            pipController = AVPictureInPictureController(playerLayer: playerView.playerLayer)
            pipController.delegate = self
            pipPossibleObservation = pipController.observe(
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
        let resList = resolutions ?? ["480p": playerConfiguration.url]
        sortedResolutions = Array(resList.keys).sorted().reversed()
        Array(resList.keys).sorted().reversed().forEach { quality in
            if quality == "1080p" {
                sortedResolutions.removeLast()
                sortedResolutions.insert("1080p", at: 1)
            }
        }
        view.backgroundColor = .black
        playerView.delegate = self
        playerView.playerConfiguration = playerConfiguration
        view.addSubview(playerView)
        playerView.edgesToSuperview()
        view.addSubview(screenshotPreventView)
        screenshotPreventView.edgesToSuperview()
        screenshotPreventView.preventScreenCapture = true
    }

    override func viewWillAppear(_ animated: Bool) {
        switchToLocalPlayback()
        setupPictureInPicture()
        super.viewWillAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        playerView.changeConstraints()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let orientation = windowScene.interfaceOrientation
            if orientation == .landscapeLeft || orientation == .landscapeRight {
                addVideosLandscapeConstraints()
            } else {
                addVideoPortraitConstraints()
            }
        }

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

    func populateMediaInfo(_ autoPlay: Bool, playPosition: TimeInterval) {
        playerView.loadMedia(autoPlay: autoPlay, playPosition: playPosition, area: view.safeAreaLayoutGuide)
    }

    func switchToLocalPlayback() {
        let playPosition: TimeInterval = TimeInterval(playerConfiguration.lastPosition)
        populateMediaInfo(true, playPosition: playPosition)
    }

    private func addVideosLandscapeConstraints() {
        portraitConstraints.deActivate()
        landscapeConstraints.append(contentsOf: playerView.edgesToSuperview())
    }

    private func addVideoPortraitConstraints() {
        landscapeConstraints.deActivate()
        portraitConstraints.append(contentsOf: playerView.center(in: view))
        portraitConstraints.append(contentsOf: playerView.edgesToSuperview())
    }

    func close(duration: [Int]) {
        if UIDevice.current.userInterfaceIdiom != .pad {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let orientation = windowScene.interfaceOrientation
                if orientation == .landscapeLeft || orientation == .landscapeRight {
                    changeOrientation()
                }
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
                ) {
                    error in
                    print(error)
                    print(windowScene.effectiveGeometry)
                }
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
        vc.settingModel = [
            SettingModel(leftIcon: Svg.settings!, title: qualityLabelText, configureLabel: selectedQualityText),
            SettingModel(leftIcon: Svg.playSpeed!, title: speedLabelText, configureLabel: selectedSpeedText),
        ]
        self.present(vc, animated: true, completion: nil)
    }

    func togglePictureInPictureMode() {
        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else {
            pipController.startPictureInPicture()
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "pip" {
            if self.pipController.isPictureInPictureActive {
                self.playerView.isHiddenPiP(isPiP: true)
            } else {
                self.playerView.isHiddenPiP(isPiP: false)
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
            //            showAudioTrackBottomSheet()
            break
        default:
            break
        }
    }

    // bottom sheet tapped
    func onBottomSheetCellTapped(index: Int, type: BottomSheetType) {
        switch type {
        case .quality:
            let resList = resolutions ?? ["480p": playerConfiguration.url]
            self.selectedQualityText = sortedResolutions[index]
            let url = resList[sortedResolutions[index]]
            self.playerView.changeQuality(url: url)
            self.url = url
            break
        case .speed:
            self.playerRate = Float(speedList[index])!
            self.selectedSpeedText = isRegular ? "\(self.playerRate)x(Обычный)" : "\(self.playerRate)x"
            self.playerView.changeSpeed(rate: self.playerRate)
            break
        case .subtitle:
            var subtitles = playerView.setSubtitleCurrentItem()
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
        bottomSheetVC.labelText = "Субтитле"
        bottomSheetVC.bottomSheetType = .subtitle
        bottomSheetVC.selectedIndex = subtitles.firstIndex(of: selectedSubtitle) ?? 0
        bottomSheetVC.cellDelegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.present(bottomSheetVC, animated: false, completion: nil)
        }
    }

    func showQualityBottomSheet() {
        let resList = resolutions ?? ["480p": playerConfiguration.url]
        let array = Array(resList.keys)
        var listOfQuality = [String]()
        listOfQuality = array.sorted().reversed()
        array.sorted().reversed().forEach { quality in
            if quality == "1080p" {
                listOfQuality.removeLast()
                listOfQuality.insert("1080p", at: 1)
            }
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
