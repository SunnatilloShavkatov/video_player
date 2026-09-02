//
//  Colors.swift
//  video_player
//

import Foundation

#if canImport(UIKit)
import UIKit

struct Colors {
    static let primary = UIColor(hex: "#00A4FF")
    static let white27 = UIColor(red: 1, green: 1, blue: 1, alpha: 0.27)
    static let background = UIColor(hex: "#000000")
    static let black03 = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
    static let backgroudColor = UIColor(red: 18/255, green: 18/255, blue: 18/255, alpha: 1.0)
    static let baseTextColor = UIColor(red: 157/255, green: 157/255, blue: 157/255, alpha: 1.0)
    static let channels = UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1.0)
    static let moreColor = UIColor(red: 16/255, green: 14/255, blue: 25/255, alpha: 1.0)
    static let mainBackground = UIColor(red: 17/255, green: 14/255, blue: 25/255, alpha: 1.0)
    static let seasonColor = UIColor(red: 46/255, green: 46/255, blue: 48/255, alpha: 1.0)
    static let black = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
    static let white = UIColor(hex: "#FFFFFF")
    static let primary73 = UIColor(red: 2/255, green: 12/255, blue: 36/255, alpha: 0.73)
    static let backgroundBottomSheet = UIColor(hex: "#25272D")
    static let blue = UIColor(hex: "#51A3FE")
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (no alpha)
            a = 255
            r = int >> 16
            g = int >> 8 & 0xFF
            b = int & 0xFF
        case 8: // RGBA (with alpha)
            a = int >> 24
            r = int >> 16 & 0xFF
            g = int >> 8 & 0xFF
            b = int & 0xFF
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

#elseif canImport(AppKit)
import AppKit

struct Colors {
    static let primary = NSColor(hex: "#00A4FF")
    static let white27 = NSColor(white: 1.0, alpha: 0.27)
    static let background = NSColor(hex: "#000000")
    static let black03 = NSColor(white: 0.0, alpha: 0.3)
    static let backgroundColor = NSColor(red: 18/255, green: 18/255, blue: 18/255, alpha: 1.0)
    static let baseTextColor = NSColor(red: 157/255, green: 157/255, blue: 157/255, alpha: 1.0)
    static let black = NSColor(white: 0.0, alpha: 1.0)
    static let white = NSColor(hex: "#FFFFFF")
    static let blue = NSColor(hex: "#51A3FE")
}

extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            a = 255
            r = int >> 16
            g = int >> 8 & 0xFF
            b = int & 0xFF
        case 8:
            a = int >> 24
            r = int >> 16 & 0xFF
            g = int >> 8 & 0xFF
            b = int & 0xFF
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
#endif
