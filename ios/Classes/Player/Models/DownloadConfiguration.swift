//
//  DownloadConfiguration.swift
//  udevs_video_player
//
//  Created by Udevs on 28/11/22.
//

struct DownloadConfiguration {
    var url: String
    var title: String
    
    init(url: String, title: String) {
        self.url = url
        self.title = title
    }
    
    static func fromMap(map : [String:Any]) -> DownloadConfiguration {
        return DownloadConfiguration(url: map["url"] as! String, title: map["title"] as! String)
    }
}
