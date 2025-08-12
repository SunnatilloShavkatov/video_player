import AVFAudio
import AVFoundation
import Flutter
import UIKit

public class SwiftVideoPlayerPlugin: NSObject, FlutterPlugin, VideoPlayerDelegate {
    
    public static var viewController = FlutterViewController()
    private var flutterResult: FlutterResult?
    private static var channel: FlutterMethodChannel?
    
    private var didRestorePersistenceManager = false
    fileprivate let downloadIdentifier: String
    /// The AVAssetDownloadURLSession to use for managing AVAssetDownloadTasks.
    fileprivate var assetDownloadURLSession: AVAssetDownloadURLSession!
    /// Internal map of AVAggregateAssetDownloadTask to its corresponding Asset.
    fileprivate var activeDownloadsMap = [AVAggregateAssetDownloadTask: MediaItemDownload]()
    
    override private init() {
        self.downloadIdentifier = "\(Bundle.main.bundleIdentifier ?? "video_player").background"
        super.init()
        let configuration = URLSessionConfiguration.background(withIdentifier: downloadIdentifier)
        assetDownloadURLSession = AVAssetDownloadURLSession(
            configuration: configuration,
            assetDownloadDelegate: self,
            delegateQueue: OperationQueue.main)
        restorePersistenceManager()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        guard let rootViewController = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController else {
            print("Warning: Could not cast root view controller to FlutterViewController")
            return
        }
        viewController = rootViewController
        channel = FlutterMethodChannel(name: "video_player", binaryMessenger: registrar.messenger())
        let instance = SwiftVideoPlayerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel!)
        let videoViewFactory = VideoPlayerViewFactory(registrar: registrar)
        registrar.register(videoViewFactory, withId: "plugins.video/video_player_view")
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        flutterResult = result
        switch call.method {
        case "closePlayer":
            do {
                SwiftVideoPlayerPlugin.viewController.dismiss(animated: true)
                return
            }
        case "downloadVideo":
            do {
                guard let args = call.arguments as? [String: String],
                      let downloadConfigJsonString = args["downloadConfigJsonString"],
                      let json = convertStringToDictionary(text: downloadConfigJsonString),
                      let download = DownloadConfiguration.fromMap(map: json) else {
                    flutterResult?(FlutterError(code: "INVALID_ARGS", message: "Invalid download configuration", details: nil))
                    return
                }
                setupAssetDownload(download: download)
                return
            }
        case "pauseDownload":
            do {
                guard let args = call.arguments as? [String: String],
                      let downloadConfigJsonString = args["downloadConfigJsonString"],
                      let json = convertStringToDictionary(text: downloadConfigJsonString),
                      let download = DownloadConfiguration.fromMap(map: json) else {
                    flutterResult?(FlutterError(code: "INVALID_ARGS", message: "Invalid download configuration", details: nil))
                    return
                }
                pauseDownload(for: download)
                return
            }
        case "resumeDownload":
            do {
                guard let args = call.arguments as? [String: String],
                      let downloadConfigJsonString = args["downloadConfigJsonString"],
                      let json = convertStringToDictionary(text: downloadConfigJsonString),
                      let download = DownloadConfiguration.fromMap(map: json) else {
                    flutterResult?(FlutterError(code: "INVALID_ARGS", message: "Invalid download configuration", details: nil))
                    return
                }
                resumeDownload(for: download)
                return
            }
        case "getStateDownload":
            do {
                guard let args = call.arguments as? [String: String],
                      let downloadConfigJsonString = args["downloadConfigJsonString"],
                      let json = convertStringToDictionary(text: downloadConfigJsonString),
                      let download = DownloadConfiguration.fromMap(map: json) else {
                    flutterResult?(FlutterError(code: "INVALID_ARGS", message: "Invalid download configuration", details: nil))
                    return
                }
                getStateDownload(for: download)
                return
            }
        case "getBytesDownloaded":
            do {
                guard let args = call.arguments as? [String: String],
                      let downloadConfigJsonString = args["downloadConfigJsonString"],
                      let json = convertStringToDictionary(text: downloadConfigJsonString),
                      let download = DownloadConfiguration.fromMap(map: json) else {
                    flutterResult?(FlutterError(code: "INVALID_ARGS", message: "Invalid download configuration", details: nil))
                    return
                }
                getStateDownload(for: download)
                return
            }
        case "getContentBytesDownload":
            do {
                guard let args = call.arguments as? [String: String],
                      let downloadConfigJsonString = args["downloadConfigJsonString"],
                      let json = convertStringToDictionary(text: downloadConfigJsonString),
                      let download = DownloadConfiguration.fromMap(map: json) else {
                    flutterResult?(FlutterError(code: "INVALID_ARGS", message: "Invalid download configuration", details: nil))
                    return
                }
                getStateDownload(for: download)
                return
            }
        case "isDownloadVideo":
            do {
                guard let args = call.arguments as? [String: String],
                      let downloadConfigJsonString = args["downloadConfigJsonString"],
                      let json = convertStringToDictionary(text: downloadConfigJsonString),
                      let download = DownloadConfiguration.fromMap(map: json) else {
                    flutterResult?(FlutterError(code: "INVALID_ARGS", message: "Invalid download configuration", details: nil))
                    return
                }
                isDownloadVideo(for: download)
                return
            }
        case "playVideo":
            do {
                guard let args = call.arguments as? [String: String],
                      let playerConfigJsonString = args["playerConfigJsonString"],
                      let json = convertStringToDictionary(text: playerConfigJsonString),
                      let playerConfiguration = PlayerConfiguration.fromMap(map: json) else {
                    flutterResult?(FlutterError(code: "INVALID_ARGS", message: "Invalid player configuration", details: nil))
                    return
                }
                let sortedResolutions = SortFunctions.sortWithKeys(playerConfiguration.resolutions)
                guard URL(string: playerConfiguration.url) != nil else {
                    flutterResult?(FlutterError(code: "INVALID_URL", message: "Invalid video URL", details: nil))
                    return
                }
                let vc = VideoPlayerViewController()
                vc.delegate = self
                vc.resolutions = sortedResolutions
                vc.modalPresentationStyle = .fullScreen
                vc.playerConfiguration = playerConfiguration
                vc.speedLabelText = playerConfiguration.speedText
                vc.qualityLabelText = playerConfiguration.qualityText
                vc.selectedQualityText = playerConfiguration.autoText
                SwiftVideoPlayerPlugin.viewController.present(vc, animated: true, completion: nil)
                return
            }
        default:
            do {
                result("Not Implemented")
                return
            }
        }
    }
    
    func getDuration(duration: [Int]) {
        flutterResult?(duration)
    }
    
    private func getPercentComplete(download: MediaItemDownload) {
        SwiftVideoPlayerPlugin.channel?.invokeMethod("percent", arguments: download.fromString())
    }
    
    /// Restores the Application state by getting all the AVAssetDownloadTasks and restoring their Asset structs.
    func restorePersistenceManager() {
        guard !didRestorePersistenceManager else { return }
        
        didRestorePersistenceManager = true
        
        // Grab all the tasks associated with the assetDownloadURLSession
        assetDownloadURLSession.getAllTasks { tasksArray in
            // For each task, restore the state in the app by recreating Asset structs and reusing existing AVURLAsset objects.
            for task in tasksArray {
                guard let assetDownloadTask = task as? AVAggregateAssetDownloadTask else { break }
                let urlAsset = assetDownloadTask.urlAsset
                _ = MediaItemDownload(url: urlAsset.url.absoluteString, percent: 100, state: nil, downloadedBytes: 0)
            }
        }
    }
    
    /// is download video
    private func isDownloadVideo(for download: DownloadConfiguration) {
        guard UserDefaults.standard.value(forKey: download.url) is String else {
            flutterResult?(false)
            return
        }
        flutterResult?(true)
        return
    }
    
    /// get state download
    private func getStateDownload(for download: DownloadConfiguration) {
        var task: AVAggregateAssetDownloadTask?
        for (taskKey, assetVal) in activeDownloadsMap where (download.url == assetVal.url) {
            task = taskKey
            break
        }
        flutterResult?(task?.state.rawValue ?? MediaItemDownload.STATE_FAILED)
    }
    
    /// download an AVAssetDownloadTask given an Asset.
    /// - Tag: DownloadDownload
    private func setupAssetDownload(download: DownloadConfiguration) {
        guard UserDefaults.standard.value(forKey: download.url) is String else {
            // Create new background session configuration.
            if let url = URL(string: download.url) {
                let asset = AVURLAsset(url: url)
                // Get the default media selections for the asset's media selection groups.
                let preferredMediaSelection = asset.preferredMediaSelection
                // Create new AVAssetDownloadTask for the desired asset
                guard
                    let downloadTask = assetDownloadURLSession.aggregateAssetDownloadTask(
                        with: asset, mediaSelections: [preferredMediaSelection],
                        assetTitle: "Some Title",
                        assetArtworkData: nil,
                        options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000])
                else { return }
                downloadTask.taskDescription = asset.description
                activeDownloadsMap[downloadTask] = MediaItemDownload(url: download.url, percent: 0, state: MediaItemDownload.STATE_RESTARTING, downloadedBytes: 0)
                downloadTask.resume()
            }
            return
        }
        getPercentComplete(download: MediaItemDownload(url: download.url, percent: 100, state: MediaItemDownload.STATE_COMPLETED, downloadedBytes: 0))
    }
    
    /// Cancels an AVAssetDownloadTask given an Asset.
    /// - Tag: CancelDownload
    func cancelDownload(for asset: MediaItemDownload) {
        var task: AVAggregateAssetDownloadTask?
        
        for (taskKey, assetVal) in activeDownloadsMap where (asset.url == assetVal.url) {
            task = taskKey
            break
        }
        
        task?.cancel()
    }
    
    /// suspend an AVAssetDownloadTask given an Asset.
    /// - Tag: SuspendDownload
    func pauseDownload(for asset: DownloadConfiguration) {
        var task: AVAggregateAssetDownloadTask?
        for (taskKey, assetVal) in activeDownloadsMap where asset.url == assetVal.url {
            task = taskKey
            break
        }
        task?.suspend()
    }
    
    /// Resume an AVAssetDownloadTask given an Asset.
    /// - Tag: ResumeDownload
    func resumeDownload(for asset: DownloadConfiguration) {
        var task: AVAggregateAssetDownloadTask?
        for (taskKey, assetVal) in activeDownloadsMap where asset.url == assetVal.url {
            task = taskKey
            break
        }
        task?.resume()
    }
}

/// Extend `SwiftVideoPlayerPlugin` to conform to the `AVAssetDownloadDelegate` protocol.
extension SwiftVideoPlayerPlugin: AVAssetDownloadDelegate {
    
    /// Tells the delegate that the task finished transferring data.
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = task as? AVAggregateAssetDownloadTask,
              let mediaDownload = activeDownloadsMap[downloadTask] else {
            return
        }
        
        if let error = error {
            print("Download failed with error: \(error.localizedDescription)")
            getPercentComplete(download: MediaItemDownload(
                url: mediaDownload.url,
                percent: mediaDownload.percent,
                state: MediaItemDownload.STATE_FAILED,
                downloadedBytes: mediaDownload.downloadedBytes
            ))
        } else {
            print("Download completed successfully for: \(mediaDownload.url)")
        }
        
        // Clean up
        activeDownloadsMap.removeValue(forKey: downloadTask)
    }
    
    /// Method called when the an aggregate download task determines the location this asset will be downloaded to.
    public func urlSession(
        _ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
        willDownloadTo location: URL
    ) {
        // Check if download is completed (state rawValue 3 = completed)
        if aggregateAssetDownloadTask.state == .completed {
            getPercentComplete(
                download: MediaItemDownload(
                    url: aggregateAssetDownloadTask.urlAsset.url.absoluteString,
                    percent: 100,
                    state: MediaItemDownload.STATE_COMPLETED,
                    downloadedBytes: Int(aggregateAssetDownloadTask.countOfBytesReceived)
                )
            )
            // Store the download location for offline playback
            UserDefaults.standard.set(location.relativePath, forKey: aggregateAssetDownloadTask.urlAsset.url.absoluteString)
        }
    }
    
    /// Method called when a child AVAssetDownloadTask completes.
    public func urlSession(
        _ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
        didCompleteFor mediaSelection: AVMediaSelection
    ) {
        guard let mediaDownload = activeDownloadsMap[aggregateAssetDownloadTask] else { return }
        
        print("Media selection completed for download: \(mediaDownload.url)")
        // Additional completion handling can be added here if needed
    }
    
    /// Method to adopt to subscribe to progress updates of an AVAggregateAssetDownloadTask.
    public func urlSession(
        _ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
        didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue],
        timeRangeExpectedToLoad: CMTimeRange, for mediaSelection: AVMediaSelection
    ) {
        guard activeDownloadsMap[aggregateAssetDownloadTask] != nil else { return }
        
        var percentComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange: CMTimeRange = value.timeRangeValue
            percentComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        
        // Convert to percentage and ensure it's between 0-100
        percentComplete = min(max(percentComplete * 100, 0), 100)
        
        print("Download progress: \(Int(percentComplete))% for URL: \(aggregateAssetDownloadTask.urlAsset.url.absoluteString)")
        
        getPercentComplete(
            download: MediaItemDownload(
                url: aggregateAssetDownloadTask.urlAsset.url.absoluteString,
                percent: Int(percentComplete),
                state: percentComplete >= 100 ? MediaItemDownload.STATE_COMPLETED : MediaItemDownload.STATE_DOWNLOADING,
                downloadedBytes: Int(aggregateAssetDownloadTask.countOfBytesReceived)
            )
        )
    }
}
