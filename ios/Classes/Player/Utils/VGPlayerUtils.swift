//
//  VGPlayerUtils.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 21/04/22.
//


import UIKit
import AVFoundation

public enum VGPlayerMediaFormat : String{
    case unknown
    case mpeg4
    case m3u8
    case mov
    case m4v
    case error
}


class VGPlayerUtils: NSObject {
    static public func playerBundle() -> Bundle {
        return Bundle(for: AVPlayer.self)
    }
    
    static public func getTimeString(from time: CMTime) -> String {
        let totalSeconds : Float64 = CMTimeGetSeconds(time)
        let hours = Int(totalSeconds/3600)
        let minutes = Int(totalSeconds/60) % 60
        
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%i:%02i:%02i", arguments: [hours,minutes,seconds])
        } else {
            return String(format: "%02i:%02i", arguments: [minutes,seconds])
        }
    }
    static public func getTimeIntString(from time: Int) -> String {
        let totalSeconds : Float64 = Float64(time)
        let hours = Int(totalSeconds/3600)
        let minutes = Int(totalSeconds/60) % 60
        
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%i:%02i:%02i", arguments: [hours,minutes,seconds])
        } else {
            return String(format: "%02i:%02i", arguments: [minutes,seconds])
        }
    }
    
    static public func fileResource(_ fileName: String, fileType: String) -> String? {
        let bundle = playerBundle()
        let path = bundle.path(forResource: fileName, ofType: fileType)
        return path
    }
    
    static public func imageResource(_ name: String) -> UIImage? {
        let bundle = playerBundle()
        return UIImage(named: name, in: bundle, compatibleWith: nil)
    }
    
    static func imageSize(image: UIImage, scaledToSize newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage;
    }
    
    static func decoderVideoFormat(_ URL: URL?) -> VGPlayerMediaFormat {
        if URL == nil {
            return .error
        }
        if let path = URL?.absoluteString{
            if path.contains(".mp4") {
                return .mpeg4
            } else if path.contains(".m3u8") {
                return .m3u8
            } else if path.contains(".mov") {
                return .mov
            } else if path.contains(".m4v"){
                return .m4v
            } else {
                return .unknown
            }
        } else {
            return .error
        }
    }
}

struct SortFunctions{
    
    static func sortWithKeys(_ dict: [String: String]) -> [String: String] {
        let sorted = dict.sorted(by: >)
        var newDict: [String: String] = [:]
        for sortedDict in sorted {
            newDict[sortedDict.key] = sortedDict.value
        }
        return newDict
    }
}

enum SwipeDirection: Int {
    case horizontal = 0
    case vertical   = 1
}

struct Constants {
    static let horizontalSpacing: CGFloat = 0
    static let controlButtonSize: CGFloat = 55.0
    static let maxButtonSize: CGFloat = 40.0
    static let bottomViewButtonSize: CGFloat = 16
    static let unblockButtonSize : CGFloat = 32.0
    static let unblockButtonInset : CGFloat = 24.0
    static let bottomViewButtonInset: CGFloat = 24.0
    static let topButtonSize: CGFloat = 50.0
    static let controlButtonInset: CGFloat = 48
    static let alphaValue: CGFloat = 0.3
    static let topButtonInset: CGFloat = 34
    static let nextEpisodeInset: CGFloat = 20
    static let nextEpisodeShowTime : Float = 60
}

func convertStringToDictionary(text: String) -> [String:Any]? {
   if let data = text.data(using: .utf8) {
       do {
           let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
           return json
       } catch {
           print("Something went wrong")
       }
   }
   return nil
}
