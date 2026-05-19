//
//  Svg.swift
//  video_player
//
//  Created by Sunnatillo Shavkatov on 23/09/22.
//

import Foundation
import UIKit

private let resourceBundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: SwiftVideoPlayerPlugin.self)
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
