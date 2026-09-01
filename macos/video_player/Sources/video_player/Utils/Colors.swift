//
//  Colors.swift
//  video_player
//

import AppKit
import Foundation

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
