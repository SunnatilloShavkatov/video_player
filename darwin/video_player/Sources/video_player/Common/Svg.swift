//
//  Svg.swift
//  video_player
//

import Foundation

#if os(iOS)
import UIKit

private let resourceBundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    let bundle = Bundle(for: VideoPlayerPlugin.self)
    if let path = bundle.path(forResource: "video_player", ofType: "bundle"),
       let subBundle = Bundle(path: path) {
        return subBundle
    }
    return bundle
    #endif
}()

struct Svg {
    static let play: UIImage? = UIImage(named: "play", in: resourceBundle, compatibleWith: nil)
    static let pause: UIImage? = UIImage(named: "pause", in: resourceBundle, compatibleWith: nil)
    static let exit: UIImage? = UIImage(named: "exit", in: resourceBundle, compatibleWith: nil)
    static let screencast: UIImage? = UIImage(named: "screencast", in: resourceBundle, compatibleWith: nil)
    static let down: UIImage? = UIImage(named: "down", in: resourceBundle, compatibleWith: nil)
    static let pip: UIImage? = UIImage(named: "pip", in: resourceBundle, compatibleWith: nil)
    static let rewind: UIImage? = UIImage(named: "rewind", in: resourceBundle, compatibleWith: nil)
    static let forward: UIImage? = UIImage(named: "forward", in: resourceBundle, compatibleWith: nil)
    static let rotate: UIImage? = UIImage(named: "rotate", in: resourceBundle, compatibleWith: nil)
    static let back: UIImage? = UIImage(named: "back", in: resourceBundle, compatibleWith: nil)
    static let right: UIImage? = UIImage(named: "right", in: resourceBundle, compatibleWith: nil)
    static let done: UIImage? = UIImage(named: "done", in: resourceBundle, compatibleWith: nil)
    static let playSpeed: UIImage? = UIImage(named: "play_speed", in: resourceBundle, compatibleWith: nil)
    static let settings: UIImage? = UIImage(named: "settings", in: resourceBundle, compatibleWith: nil)
    static let share: UIImage? = UIImage(named: "share", in: resourceBundle, compatibleWith: nil)
}

#elseif os(macOS)
import AppKit

private let resourceBundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    let bundle = Bundle(for: VideoPlayerPlugin.self)
    if let path = bundle.path(forResource: "video_player", ofType: "bundle"),
       let subBundle = Bundle(path: path) {
        return subBundle
    }
    return bundle
    #endif
}()

struct Svg {
    static var play: NSImage? { image(named: "play") }
    static var pause: NSImage? { image(named: "pause") }
    static var exit: NSImage? { image(named: "exit") }
    static var screencast: NSImage? { image(named: "screencast") }
    static var down: NSImage? { image(named: "down") }
    static var pip: NSImage? { image(named: "pip") }
    static var rewind: NSImage? { image(named: "rewind") }
    static var forward: NSImage? { image(named: "forward") }
    static var rotate: NSImage? { image(named: "rotate") }
    static var back: NSImage? { image(named: "back") }
    static var right: NSImage? { image(named: "right") }
    static var done: NSImage? { image(named: "done") }
    static var playSpeed: NSImage? { image(named: "play_speed") }
    static var settings: NSImage? { image(named: "settings") }
    static var share: NSImage? { image(named: "share") }

    private static func image(named name: String) -> NSImage? {
        if let image = resourceBundle.image(forResource: name) {
            image.isTemplate = false
            return image
        }
        if let path = resourceBundle.path(forResource: name, ofType: "png"),
           let image = NSImage(contentsOfFile: path) {
            image.isTemplate = false
            return image
        }
        if let mainPath = Bundle.main.path(forResource: name, ofType: "png"),
           let image = NSImage(contentsOfFile: mainPath) {
            image.isTemplate = false
            return image
        }
        return NSImage(named: NSImage.Name(name))
    }
}
#endif
