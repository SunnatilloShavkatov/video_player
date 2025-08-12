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
    var resolutions: [String:String]
    var initialResolution: [String:String]
    
    init(initialResolution: [String : String], resolutions: [String : String], qualityText: String, speedText: String, lastPosition: Int, title: String, playVideoFromAsset: Bool, assetPath: String? = nil, autoText: String, url: String, movieShareLink: String,) {
        self.url = url
        self.title = title
        self.lastPosition = lastPosition
        self.speedText = speedText
        self.autoText = autoText
        self.assetPath = assetPath
        self.qualityText = qualityText
        self.movieShareLink = movieShareLink
        self.playVideoFromAsset = playVideoFromAsset
        self.resolutions = resolutions
        self.initialResolution = initialResolution
    }
    
    static func fromMap(map: [String: Any]) -> PlayerConfiguration? {
        guard let initialResolution = map["initialResolution"] as? [String: String],
              let resolutions = map["resolutions"] as? [String: String],
              let qualityText = map["qualityText"] as? String,
              let speedText = map["speedText"] as? String,
              let lastPosition = map["lastPosition"] as? Int,
              let title = map["title"] as? String,
              let playVideoFromAsset = map["playVideoFromAsset"] as? Bool,
              let autoText = map["autoText"] as? String,
              let movieShareLink = map["movieShareLink"] as? String else {
            return nil
        }
        
        let assetPath = map["assetPath"] as? String
        let url = initialResolution.values.first ?? ""
        
        return PlayerConfiguration(
            initialResolution: initialResolution,
            resolutions: resolutions,
            qualityText: qualityText,
            speedText: speedText,
            lastPosition: lastPosition,
            title: title,
            playVideoFromAsset: playVideoFromAsset,
            assetPath: assetPath,
            autoText: autoText,
            url: url,
            movieShareLink: movieShareLink
        )
    }
}
