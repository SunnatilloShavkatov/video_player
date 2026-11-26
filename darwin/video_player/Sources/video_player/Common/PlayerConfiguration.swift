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
    var subtitleText: String
    var subtitleSizeText: String
    var subtitleOffText: String
    var keyRequestHeaders: [String: String]

    init(qualityText: String, speedText: String, lastPosition: Int, title: String, playVideoFromAsset: Bool, assetPath: String? = nil, autoText: String, url: String, movieShareLink: String, isScreenshotEnabled: Bool = false, subtitles: [SubtitleTrack] = [], subtitleText: String = "Subtitles", subtitleSizeText: String = "Subtitle Size", subtitleOffText: String = "Off", keyRequestHeaders: [String: String] = [:]) {
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
        self.subtitleText = subtitleText
        self.subtitleSizeText = subtitleSizeText
        self.subtitleOffText = subtitleOffText
        self.keyRequestHeaders = keyRequestHeaders
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
        let subtitleText = map["subtitleText"] as? String ?? "Subtitles"
        let subtitleSizeText = map["subtitleSizeText"] as? String ?? "Subtitle Size"
        let subtitleOffText = map["subtitleOffText"] as? String ?? "Off"
        let keyRequestHeaders = map["keyRequestHeaders"] as? [String: String] ?? [:]

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
            subtitles: subtitles,
            subtitleText: subtitleText,
            subtitleSizeText: subtitleSizeText,
            subtitleOffText: subtitleOffText,
            keyRequestHeaders: keyRequestHeaders
        )
    }
}
