//
//  Colors.swift
//  udevs_video_player
//
//  Created by Udevs on 22/09/22.
//

import Foundation

struct Colors {
    
    static let primary = UIColor(hex: "#51A3FE")
    static let white50 = UIColor(red:1, green: 1, blue: 1, alpha: 0.5)
    static let backgroud = UIColor(hex: "#000000")
    
    static let black03 = UIColor(red:0, green: 0, blue: 0, alpha: 0.3)
    
    static let backgroudColor = UIColor(red: 18, green: 18, blue: 18)
    static let baseTextColor = UIColor(red: 157, green: 157, blue: 157)
    static let channels = UIColor(red: 30, green: 30, blue: 30)
    static let moreColor = UIColor(red:16, green: 14, blue: 25)
    static let mainBackground = UIColor(red: 17, green: 14, blue: 25)
    static let seasonColor = UIColor(red: 46, green: 46, blue: 48)
    static let black = UIColor(red:0, green: 0, blue: 0)
    static let white = UIColor(red:1, green: 1, blue: 1)
    static let primary73 = UIColor(red: 2/255, green: 12/255, blue: 36/255, alpha: 0.73)
    static let backgroundBottomSheet = UIColor(hex: "#1C1C1E")
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
