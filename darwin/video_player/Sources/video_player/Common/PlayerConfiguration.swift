//
//  PlayerConfiguration.swift
//  video_player
//
//  Created by Sunnatillo Shavkatov on 23/06/25.
//

import Foundation

struct PlayerConfiguration{
    var url: String
    var title: String
    var speedText: String
    var lastPosition: Int
    var autoText: String
    var assetPath: String?
    var qualityText: String
    var movieShareLink: String
    var playVideoFromAsset: Bool
    var isScreenshotEnabled: Bool
    var subtitles: [SubtitleTrack]

    init(qualityText: String, speedText: String, lastPosition: Int, title: String, playVideoFromAsset: Bool, assetPath: String? = nil, autoText: String, url: String, movieShareLink: String, isScreenshotEnabled: Bool = false, subtitles: [SubtitleTrack] = []) {
        self.url = url
        self.title = title
        self.lastPosition = lastPosition
        self.speedText = speedText
        self.autoText = autoText
        self.assetPath = assetPath
        self.qualityText = qualityText
        self.movieShareLink = movieShareLink
        self.playVideoFromAsset = playVideoFromAsset
        self.isScreenshotEnabled = isScreenshotEnabled
        self.subtitles = subtitles
    }
    
    static func fromMap(map: [String: Any]) -> PlayerConfiguration? {
        guard let videoUrl = map["videoUrl"] as? String,
              let qualityText = map["qualityText"] as? String,
              let speedText = map["speedText"] as? String,
              let lastPosition = (map["lastPosition"] as? NSNumber)?.intValue ?? (map["lastPosition"] as? Int),
              let title = map["title"] as? String,
              let playVideoFromAsset = map["playVideoFromAsset"] as? Bool,
              let autoText = map["autoText"] as? String,
              let movieShareLink = map["movieShareLink"] as? String else {
            return nil
        }

        let assetPath = map["assetPath"] as? String
        let isScreenshotEnabled = map["isScreenshotEnabled"] as? Bool ?? false
        let subtitles = (map["subtitles"] as? [[String: Any]])?.compactMap { SubtitleTrack.fromMap($0) } ?? []

        return PlayerConfiguration(
            qualityText: qualityText,
            speedText: speedText,
            lastPosition: lastPosition,
            title: title,
            playVideoFromAsset: playVideoFromAsset,
            assetPath: assetPath,
            autoText: autoText,
            url: videoUrl,
            movieShareLink: movieShareLink,
            isScreenshotEnabled: isScreenshotEnabled,
            subtitles: subtitles
        )
    }
}
