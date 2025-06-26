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
    
    static func fromMap(map : [String:Any])->PlayerConfiguration {
        return PlayerConfiguration(initialResolution: map["initialResolution"] as! [String:String],
                                   resolutions: map["resolutions"] as! [String:String],
                                   qualityText: map["qualityText"] as! String,
                                   speedText: map["speedText"] as! String,
                                   lastPosition: map["lastPosition"] as! Int,
                                   title: map["title"] as! String,
                                   playVideoFromAsset : map["playVideoFromAsset"] as! Bool,
                                   assetPath:map["assetPath"] as? String,
                                   autoText: map["autoText"] as! String,
                                   url: (map["initialResolution"] as! [String:String]).values.first ?? "",
                                   movieShareLink: map["movieShareLink"] as! String
        )
    }
}
