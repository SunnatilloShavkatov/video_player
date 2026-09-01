//
//  VGPlayerUtils.swift
//  video_player
//

import AVFoundation
import Foundation

struct VideoSourceResolutionFailure: Error {
    let code: String
    let message: String
}

func videoGravity(s: String?) -> AVLayerVideoGravity {
    switch s {
    case "fit":
        return .resizeAspect
    case "fill":
        return .resizeAspectFill
    case "zoom":
        return .resize
    default:
        return .resizeAspect
    }
}

func convertStringToDictionary(text: String) -> [String: Any]? {
    guard let data = text.data(using: .utf8) else { return nil }
    do {
        let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
        return json
    } catch {
        return nil
    }
}
