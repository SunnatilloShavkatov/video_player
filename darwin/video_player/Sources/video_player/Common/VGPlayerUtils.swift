//
//  VGPlayerUtils.swift
//  video_player
//

import AVFoundation
import Foundation

class VGPlayerUtils: NSObject {
    static public func getTimeString(from time: CMTime) -> String {
        let totalSeconds: Float64 = CMTimeGetSeconds(time)
        let hours = Int(totalSeconds / 3600)
        let minutes = Int(totalSeconds / 60) % 60
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%i:%02i:%02i", arguments: [hours, minutes, seconds])
        } else {
            return String(format: "%02i:%02i", arguments: [minutes, seconds])
        }
    }
}

func convertStringToDictionary(text: String) -> [String: Any]? {
    if let data = text.data(using: .utf8) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
            return json
        } catch {
            // Error occurred
        }
    }
    return nil
}

public func videoGravity(s: String?) -> AVLayerVideoGravity {
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
