//
//  PlayerConfiguration.swift
//  udevs_video_player
//
//  Created by Udevs on 08/10/22.
//

import Foundation

struct PlayerConfiguration{
    var initialResolution: [String:String]
    var resolutions: [String:String]
    var url, qualityText: String
    var speedText: String
    var lastPosition: Int
    var title: String
    var isSerial: Bool
    var episodeButtonText: String
    var nextButtonText: String
    var seasons: [Season]
    var isLive: Bool
    var tvProgramsText: String
    var programsInfoList: [ProgramInfo]
    var showController: Bool
    var playVideoFromAsset: Bool
    var assetPath: String?
    var seasonIndex: Int
    var episodeIndex: Int
    var isMegogo: Bool
    var isPremier: Bool
    var videoId: String
    var sessionId: String
    var megogoAccessToken: String
    var authorization: String
    var autoText: String
    var baseUrl: String
    var movieShareLink: String
    var selectChannelIndex: Int
    var selectTvCategoryIndex: Int
    var tvCategories: [TvCategories]
    
    init(initialResolution: [String : String], resolutions: [String : String], qualityText: String, speedText: String, lastPosition: Int, title: String, isSerial: Bool, episodeButtonText: String, nextButtonText: String, seasons: [Season], isLive: Bool, tvProgramsText: String, programsInfoList: [ProgramInfo], showController: Bool, playVideoFromAsset: Bool, assetPath: String? = nil, seasonIndex: Int, episodeIndex: Int, isMegogo: Bool, isPremier: Bool, videoId: String, sessionId: String, megogoAccessToken: String, authorization: String, autoText: String, baseUrl: String,url: String,movieShareLink: String, selectChannelIndex: Int, selectTvCategoryIndex: Int, tvCategories: [TvCategories]) {
        self.initialResolution = initialResolution
        self.resolutions = resolutions
        self.qualityText = qualityText
        self.speedText = speedText
        self.lastPosition = lastPosition
        self.title = title
        self.isSerial = isSerial
        self.episodeButtonText = episodeButtonText
        self.nextButtonText = nextButtonText
        self.seasons = seasons
        self.isLive = isLive
        self.tvProgramsText = tvProgramsText
        self.programsInfoList = programsInfoList
        self.showController = showController
        self.playVideoFromAsset = playVideoFromAsset
        self.assetPath = assetPath
        self.seasonIndex = seasonIndex
        self.episodeIndex = episodeIndex
        self.isMegogo = isMegogo
        self.isPremier = isPremier
        self.videoId = videoId
        self.sessionId = sessionId
        self.megogoAccessToken = megogoAccessToken
        self.authorization = authorization
        self.autoText = autoText
        self.baseUrl = baseUrl
        self.url = url
        self.movieShareLink = movieShareLink
        self.selectChannelIndex = selectChannelIndex
        self.selectTvCategoryIndex = selectTvCategoryIndex
        self.tvCategories = tvCategories
    }
    
    static func fromMap(map : [String:Any])->PlayerConfiguration {
        var season : [Season] = []
        var programInfos: [ProgramInfo] = []
        var tvCategories: [TvCategories] = []
        var programsInfoListMap : [Dictionary<String, Any>]?
        var tvCategoriesMap : [Dictionary<String, Any>]?
        var seasonsMap : [Dictionary<String, Any>]?
        var channelsMap : [Dictionary<String, Any>]?
        programsInfoListMap = map["programsInfoList"] as? [Dictionary<String, Any>]
        seasonsMap = map["seasons"] as! [Dictionary<String, Any>]
        tvCategoriesMap = map["tvCategories"] as! [Dictionary<String, Any>]
        programsInfoListMap?.forEach({ data in
            let program = ProgramInfo.fromMap(map: data)
            programInfos.append(program)
        })
        seasonsMap?.forEach({ data in
            let program = Season.fromMap(map: data)
            season.append(program)
        })
        tvCategoriesMap?.forEach({ data in
            let program = TvCategories.fromMap(map: data)
            tvCategories.append(program)
        })
        
        return PlayerConfiguration(initialResolution: map["initialResolution"] as! [String:String],
                                   resolutions: map["resolutions"] as! [String:String],
                                   qualityText: map["qualityText"] as! String,
                                   speedText: map["speedText"] as! String,
                                   lastPosition: map["lastPosition"] as! Int,
                                   title: map["title"] as! String,
                                   isSerial: map["isSerial"] as! Bool,
                                   episodeButtonText: map["episodeButtonText"] as! String,
                                   nextButtonText: map["nextButtonText"] as! String,
                                   seasons: season,
                                   isLive: map["isLive"] as! Bool,
                                   tvProgramsText: map["tvProgramsText"] as! String,
                                   programsInfoList: programInfos,
                                   showController : map["showController"] as! Bool,
                                   playVideoFromAsset : map["playVideoFromAsset"] as! Bool,
                                   assetPath:map["assetPath"] as? String,
                                   seasonIndex: map["seasonIndex"] as! Int,
                                   episodeIndex: map["episodeIndex"] as! Int,
                                   isMegogo: map["isMegogo"] as! Bool,
                                   isPremier: map["isPremier"] as! Bool,
                                   videoId: map["videoId"] as! String,
                                   sessionId: map["sessionId"] as! String,
                                   megogoAccessToken: map["megogoAccessToken"] as! String,
                                   authorization: map["authorization"] as! String,
                                   autoText: map["autoText"] as! String,
                                   baseUrl: map["baseUrl"] as! String,
                                   url: (map["initialResolution"] as! [String:String]).values.first ?? "",
                                   movieShareLink: map["movieShareLink"] as! String,
                                   selectChannelIndex: map["selectChannelIndex"] as? Int ?? 0, selectTvCategoryIndex: map["selectTvCategoryIndex"] as? Int ?? 0,
                                   tvCategories: tvCategories
                                   
        )
    }
}


struct Season {
    var title: String?
    var movies: [Movie]
    init(title: String? = nil, movies: [Movie]) {
        self.title = title
        self.movies = movies
    }
    
    static func fromMap(map : [String:Any])->Season{
        var s: [Movie] = []
        var movies: [Dictionary<String, Any>]?
        movies = map["movies"] as! [Dictionary<String, Any>]?
        movies?.forEach { data in
            let movi = Movie.fromMap(map: data)
            s.append(movi)
        }
        return Season(title:  map["title"] as? String, movies: s)
    }
}

struct Movie {
    var id: String?
    var title: String?
    var description: String?
    var image: String?
    var duration: Int?
    var resolutions: [String:String]
    
    init(id: String? = nil, title: String? = nil, description: String? = nil, image: String? = nil, duration: Int? = nil, resolutions: [String : String]) {
        self.id = id
        self.title = title
        self.description = description
        self.image = image
        self.duration = duration
        self.resolutions = resolutions
    }
    
    static func fromMap(map : [String:Any])->Movie{
        return Movie(id: (map["id"] as? String),title: (map["title"] as? String), description: map["description"] as? String, image: (map["image"] as? String), duration: (map["duration"] as? Int), resolutions: (map["resolutions"] as! [String:String]))
    }
}

struct ProgramInfo {
    var day: String
    var tvPrograms: [TvProgram]?
    init(day: String, tvPrograms: [TvProgram]? = nil) {
        self.day = day
        self.tvPrograms = tvPrograms
    }
    static func fromMap(map : [String:Any])->ProgramInfo{
        var tv: [TvProgram] = []
        var tvPrograms: [Dictionary<String, Any>]?
        tvPrograms = map["tvPrograms"] as! [Dictionary<String, Any>]?
        tvPrograms?.forEach { data in
            let tvProgram = TvProgram.fromMap(map: data as! [String:String])
            tv.append(tvProgram)
        }
        return ProgramInfo(day: map["day"] as! String,tvPrograms: tv )
    }
}

struct TvProgram{
    var scheduledTime: String?
    var programTitle: String?
    init(scheduledTime: String? = nil, programTitle: String? = nil) {
        self.scheduledTime = scheduledTime
        self.programTitle = programTitle
    }
    
    static func fromMap(map : [String:String])->TvProgram{
        return TvProgram(scheduledTime: map["scheduledTime"]!, programTitle: map["programTitle"]!)
    }
}

struct Channel {
    var id: String?
    var image: String?
    var name: String?
    var resolutions: [String:String]
    
    init(id: String? = nil, name: String? = nil, image: String? = nil, resolutions: [String : String]) {
        self.id = id
        self.name = name
        self.image = image
        self.resolutions = resolutions
    }
    
    static func fromMap(map : [String:Any])-> Channel{
        return Channel(id: (map["id"] as? String),name:(map["name"] as? String), image: (map["image"] as? String), resolutions: (map["resolutions"] as! [String:String]))
    }
}

extension Channel: Equatable {
     static func == (lhs: Channel, rhs: Channel) -> Bool {
         lhs.id == rhs.id && lhs.name == rhs.name && lhs.image == rhs.image
     }
 }
struct TvCategories{
    var id: String?
    var title: String?
    var channels: [Channel]
    
    init(id: String? = nil, title: String? = nil, channels: [Channel]) {
        self.id = id
        self.title = title
        self.channels = channels
    }
    
    static func fromMap(map : [String:Any])-> TvCategories{
        var channels : [Channel] = []
        var channelsMap : [Dictionary<String, Any>]?
        channelsMap = map["tvChannels"] as? [Dictionary<String, Any>]
        channelsMap?.forEach({ data in
            let program = Channel.fromMap(map: data)
            channels.append(program)
        })
        return TvCategories(id: (map["id"] as? String),title: map["title"] as? String, channels: channels)
    }
}
