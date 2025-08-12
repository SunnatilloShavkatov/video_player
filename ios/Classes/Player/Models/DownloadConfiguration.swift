//
//  DownloadConfiguration.swift
//  video_player
//
//  Created by Sunnatillo Shavkatov on 23/06/25.
//

import Foundation

struct DownloadConfiguration {
    var url: String
    var title: String
    
    init(url: String, title: String) {
        self.url = url
        self.title = title
    }
    
    static func fromMap(map: [String: Any]) -> DownloadConfiguration? {
        guard let url = map["url"] as? String,
              let title = map["title"] as? String else {
            return nil
        }
        return DownloadConfiguration(url: url, title: title)
    }
}
