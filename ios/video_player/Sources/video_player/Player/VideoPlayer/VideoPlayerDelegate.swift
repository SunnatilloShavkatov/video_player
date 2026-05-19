//
//  VideoPlayerDelegate.swift
//  video_player
//
//  Created by Sunnatillo Shavkatov on 23/06/25.
//

import Foundation

protocol VideoPlayerDelegate: AnyObject {
    func getDuration(duration: [Int])
}
protocol QualityDelegate {
    func qualityBottomSheet()
}
protocol SpeedDelegate {
    func speedBottomSheet()
}
protocol SubtitleDelegate {
    func subtitleBottomSheet()
}
