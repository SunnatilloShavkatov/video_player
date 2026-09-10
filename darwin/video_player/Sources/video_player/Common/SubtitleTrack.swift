//
//  SubtitleTrack.swift
//  video_player
//

import Foundation

public struct SubtitleTrack: Equatable {
    public let id: Int
    public let label: String
    public let lang: String
    public let isDefault: Bool
    public let url: String

    public init(id: Int, label: String, lang: String, isDefault: Bool = false, url: String) {
        self.id = id
        self.label = label
        self.lang = lang
        self.isDefault = isDefault
        self.url = url
    }

    public static func fromMap(_ map: [String: Any]) -> SubtitleTrack? {
        guard let id = (map["id"] as? NSNumber)?.intValue ?? (map["id"] as? Int),
              let label = map["label"] as? String,
              let lang = map["lang"] as? String,
              let url = map["url"] as? String else {
            return nil
        }
        let isDefault = (map["is_default"] as? Bool) ?? (map["isDefault"] as? Bool) ?? false
        return SubtitleTrack(id: id, label: label, lang: lang, isDefault: isDefault, url: url)
    }
}
