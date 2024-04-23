//
//  VideoPlayerViewController.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 21/04/22.
//

import UIKit
import TinyConstraints
import AVFoundation
import AVKit
import MediaPlayer
import XLActionController
import NVActivityIndicatorView
import SnapKit
import ScreenshotPreventing

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
    
    private var speedList = ["2.0","1.5","1.25","1.0","0.5"].sorted()
    
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
    var selectedSeason: Int = 0
    var selectSesonNum: Int = 0
    var selectChannelIndex: Int = 0
    var selectTvCategoryIndex: Int = 0
    var isRegular: Bool = false
    var resolutions: [String:String]?
    var sortedResolutions: [String] = []
    var seasons : [Season] = [Season]()
    var qualityDelegate: QualityDelegate!
    var speedDelegte: SpeedDelegate!
    var subtitleDelegte: SubtitleDelegate!
    var playerConfiguration: PlayerConfiguration!
    private var isVolume = false
    private var volumeViewSlider: UISlider!
    private var playerRate: Float = 1.0
    private var selectedSpeedText = "1.0x"
    var selectedQualityText = "Auto"
    private var selectedSubtitle = "None"
    
    lazy private var playerView: PlayerView = {
        return PlayerView()
    }()

    lazy var screenshotPreventView = ScreenshotPreventingView(contentView: playerView)
    
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
            pipPossibleObservation = pipController.observe(\AVPictureInPictureController.isPictureInPicturePossible,
                                                            options: [.initial, .new]) { [weak self] _, change in
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
        let resList = resolutions ?? ["480p":playerConfiguration.url]
        sortedResolutions = Array(resList.keys).sorted().reversed()
        Array(resList.keys).sorted().reversed().forEach { quality in
            if quality == "1080p"{
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
        if UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight {
            addVideosLandscapeConstraints()
        } else {
            addVideoPortaitConstraints()
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
    
    private func addVideoPortaitConstraints() {
        landscapeConstraints.deActivate()
        portraitConstraints.append(contentsOf: playerView.center(in: view))
        portraitConstraints.append(contentsOf: playerView.edgesToSuperview())
    }
    
    func showPressed() {
        let vc = ProgramViewController()
        vc.modalPresentationStyle = .custom
        vc.programInfo = self.playerConfiguration.programsInfoList
        vc.menuHeight = self.playerConfiguration.programsInfoList.isEmpty ? 250 : UIScreen.main.bounds.height * 0.75
        if !(vc.programInfo.isEmpty) {
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func close(duration : [Int]){
        if UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight {
            changeOrientation()
        }
        self.dismiss(animated: true, completion: nil)
        delegate?.getDuration(duration : duration)
    }
    
    func share() {
        if let link = NSURL(string: playerConfiguration.movieShareLink)
        {
            let objectsToShare = [link] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList]
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    func changeOrientation(){
        var value = UIInterfaceOrientation.landscapeRight.rawValue
        if UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight {
            value = UIInterfaceOrientation.portrait.rawValue
        }
        if #available(iOS 16.0, *) {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    return
                }
                self.setNeedsUpdateOfSupportedInterfaceOrientations()
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: (UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight) ? .portrait : .landscapeRight)){
                        error in
                        print(error)
                        print(windowScene.effectiveGeometry)
                }
        } else {
            UIDevice.current.setValue(value, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    func updateSeasonNum(index:Int) {
        selectedSeason = index
    }
    
    //MARK: - ****** Channels *******
    func channelsButtonPressed(){
        let episodeVC = CollectionViewController()
        episodeVC.modalPresentationStyle = .custom
        episodeVC.channels = self.playerConfiguration.tvCategories[selectTvCategoryIndex].channels
        episodeVC.tv = self.playerConfiguration.tvCategories
        episodeVC.delegate = self
        episodeVC.tvCategoryIndex = selectTvCategoryIndex
        self.present(episodeVC, animated: true, completion: nil)
    }
    
    //MARK: - ****** SEASONS *******
    func episodesButtonPressed(){
        let episodeVC = EpisodeCollectionUI()
        episodeVC.modalPresentationStyle = .custom
        episodeVC.seasons = self.seasons
        episodeVC.delegate = self
        episodeVC.seasonIndex = selectedSeason
        episodeVC.episodeIndex = selectSesonNum
        self.present(episodeVC, animated: true, completion: nil)
    }
    
    func settingsPressed() {
        let vc = SettingVC()
        vc.modalPresentationStyle = .custom
        vc.delegete = self
        vc.speedDelegate = self
        vc.subtitleDelegate = self
        vc.settingModel = [
            SettingModel(leftIcon: Svg.settings!, title: qualityLabelText, configureLabel: selectedQualityText),
            SettingModel(leftIcon: Svg.playSpeed!, title: speedLabelText, configureLabel:  selectedSpeedText),
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
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
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
    
    //    //MARK: - Bottom Sheets Configurations
    // bottom sheet tapped
    func onBottomSheetCellTapped(index: Int, type : BottomSheetType) {
        switch type {
        case .quality:
            let resList = resolutions ?? ["480p":playerConfiguration.url]
            self.selectedQualityText = sortedResolutions[index]
            let url = resList[sortedResolutions[index]]
            self.playerView.changeQuality(url: url)
            self.url = url
            break
        case .speed:
            self.playerRate = Float(speedList[index])!
            self.selectedSpeedText = isRegular  ? "\(self.playerRate)x(Обычный)" : "\(self.playerRate)x"
            self.playerView.changeSpeed(rate: self.playerRate)
            break
        case .subtitle:
            var subtitles = playerView.setSubtitleCurrentItem()
            let selectedSubtitleLabel = subtitles[index]
            if (playerView.getSubtitleTrackIsEmpty(selectedSubtitleLabel: selectedSubtitleLabel)){
                    selectedSubtitle = selectedSubtitleLabel
            }
            break
        case .audio:
            break
        }
    }
    
    private func showSubtitleBottomSheet(){
           let subtitles = playerView.setSubtitleCurrentItem()
           let bottomSheetVC = BottomSheetViewController()
           bottomSheetVC.modalPresentationStyle = .overCurrentContext
           bottomSheetVC.items = subtitles
           bottomSheetVC.labelText = "Субтитле"
           bottomSheetVC.bottomSheetType = .subtitle
           bottomSheetVC.selectedIndex = subtitles.firstIndex(of: selectedSubtitle) ?? 0
           bottomSheetVC.cellDelegate = self
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
               self.present(bottomSheetVC, animated: false, completion:nil)
           }
       }

    
    func showQualityBottomSheet(){
        let resList = resolutions ?? ["480p": playerConfiguration.url]
        let array = Array(resList.keys)
        var listOfQuality = [String]()
        listOfQuality = array.sorted().reversed()
        array.sorted().reversed().forEach { quality in
            if quality == "1080p"{
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
            self.present(bottomSheetVC, animated: false, completion:nil)
        }
    }
    
    func showSpeedBottomSheet(){
        let bottomSheetVC = BottomSheetViewController()
        bottomSheetVC.modalPresentationStyle = .custom
        bottomSheetVC.items = speedList
        bottomSheetVC.labelText = speedLabelText
        bottomSheetVC.cellDelegate = self
        bottomSheetVC.bottomSheetType = .speed
        bottomSheetVC.selectedIndex = speedList.firstIndex(of: "\(self.playerRate)") ?? 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.present(bottomSheetVC, animated: false, completion:nil)
        }
    }
    
    func getMegogoStream(parameters:[String:String], id:String) -> MegogoStreamResponse? {
        var megogoResponse:MegogoStreamResponse?
        let _url:String = playerConfiguration.baseUrl+"megogo/stream"
        let result = Networking.sharedInstance.getMegogoStream(_url, token: self.playerConfiguration.authorization, sessionId: id, parameters: parameters)
        switch result {
        case .failure(let error):
            print(error)
            break
        case .success(let success):
            megogoResponse = success
            break
        }
        return megogoResponse
        
    }
    
    func getPremierStream(episodeId:String) -> PremierStreamResponse?{
        let _url : String = playerConfiguration.baseUrl+"premier/videos/\(playerConfiguration.videoId)/episodes/\(episodeId)/stream"
        var premierSteamResponse: PremierStreamResponse?
        let result = Networking.sharedInstance.getPremierStream(_url, token: playerConfiguration.authorization, sessionId: playerConfiguration.sessionId)
        switch result {
        case .failure(let error):
            print(error)
        case .success(let success):
            premierSteamResponse = success
        }
        return premierSteamResponse
    }
    
    func getChannel(id : String) -> ChannelResponse? {
        let _url : String = playerConfiguration.baseUrl+"tv/channel/\(id)"
        var channelResponse: ChannelResponse?
        let result = Networking.sharedInstance.getChannel(_url, token: playerConfiguration.authorization, sessionId: playerConfiguration.sessionId,parameters: ["client_ip" : ""])
        switch result {
        case .failure(let error):
            print(error)
        case .success(let success):
            channelResponse = success
        }
        return channelResponse
    }
    
    func getStreamUrl(url : String) -> String? {
        var channelResponse: String?
        let result = Networking.sharedInstance.getStreamUrl(url)
        switch result {
        case .failure(let error):
            print(error)
        case .success(let success):
            channelResponse = success
        }
        return channelResponse
    }
    
    func playSeason(_resolutions : [String:String],startAt:Int64?,_episodeIndex:Int,_seasonIndex:Int ){
        self.selectedSeason = _seasonIndex
        self.selectSesonNum = _episodeIndex
        self.resolutions = SortFunctions.sortWithKeys(_resolutions)
        let isFinded = resolutions?.contains(where: { (key, value) in
            if key == self.selectedQualityText {
                return true
            }
            return false
        }) ?? false
        let title = seasons[_seasonIndex].movies[_episodeIndex].title ?? ""
        if isFinded {
            let videoUrl = self.resolutions?[selectedQualityText]
            guard videoUrl != nil else{
                return
            }
            guard URL(string: videoUrl!) != nil else {
                return
            }
            if self.playerConfiguration.url != videoUrl!{
                self.playerView.changeUrl(url: videoUrl, title: "S\(_seasonIndex + 1)" + " " + "E\(_episodeIndex + 1)" + " \u{22}\(title)\u{22}" )
                self.url = videoUrl
            } else {
                print("ERROR")
            }
            return
        } else if !self.resolutions!.isEmpty {
            let videoUrl = Array(resolutions!.values)[0]
            self.playerView.changeUrl(url: videoUrl, title: title)
            self.url = videoUrl
            return
        }
    }
}

extension VideoPlayerViewController: QualityDelegate, SpeedDelegate, EpisodeDelegate, SubtitleDelegate, ChannelTappedDelegate {
    
    func onTvCategoryTapped(tvCategoryIndex: Int) {
        self.selectTvCategoryIndex = tvCategoryIndex
    }
    
    func onChannelTapped(channelIndex: Int, tvCategoryIndex: Int) {
        if self.selectChannelIndex == channelIndex && self.selectTvCategoryIndex == tvCategoryIndex { return }
        let channel = self.playerConfiguration.tvCategories[tvCategoryIndex].channels[channelIndex]
        let success : ChannelResponse? = getChannel(id: channel.id ?? "")
        if success != nil {
            self.selectChannelIndex = channelIndex
            self.selectTvCategoryIndex = tvCategoryIndex
            self.url = success?.channelStreamIos ?? ""
            self.resolutions = ["Auto": success?.channelStreamIos ?? ""]
            self.playerView.changeUrl(url: self.url, title: channel.name ?? "")
        }
    }
    
    func onEpisodeCellTapped(seasonIndex: Int, episodeIndex: Int) {
        var resolutions: [String:String] = [:]
        var startAt :Int64?
        let episodeId : String = seasons[seasonIndex].movies[episodeIndex].id ?? ""
        if playerConfiguration.isMegogo {
            let parameters : [String:String] = ["video_id":episodeId,"access_token":self.playerConfiguration.megogoAccessToken]
            var success : MegogoStreamResponse?
            success = self.getMegogoStream(parameters: parameters,id: episodeId)
            if success != nil {
                
                resolutions[self.playerConfiguration.autoText] = success?.data.src
                success?.data.bitrates.forEach({ bitrate in
                    resolutions["\(bitrate.bitrate)p"] = bitrate.src
                })
                startAt = Int64(success?.data.playStartTime ?? 0)
                self.playSeason(_resolutions: resolutions, startAt: startAt, _episodeIndex: episodeIndex, _seasonIndex: seasonIndex)
            }
        }
        if playerConfiguration.isPremier {
            var success : PremierStreamResponse?
            success = self.getPremierStream(episodeId: episodeId)
            if success != nil {
                success?.fileInfo.forEach({ file in
                    if file.quality == "auto"{
                        resolutions[self.playerConfiguration.autoText] = file.fileName
                    } else {
                        resolutions["\(file.quality)"] = file.fileName
                    }
                })
                startAt = 0
                self.playSeason(_resolutions: resolutions, startAt: startAt, _episodeIndex: episodeIndex, _seasonIndex: seasonIndex)
            }
        }
        if !playerConfiguration.isMegogo && !playerConfiguration.isPremier {
            seasons[seasonIndex].movies[episodeIndex].resolutions.map { (key: String, value: String) in
                resolutions[key] = value
                startAt = 0
            }
            self.playSeason(_resolutions: resolutions, startAt: startAt, _episodeIndex: episodeIndex, _seasonIndex: seasonIndex)
        }
    }
    
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
