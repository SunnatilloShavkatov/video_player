//
//  PlayButton.swift
//  udevs_video_player
//
//  Created by Udevs on 23/10/22.
//

import Foundation

@IBDesignable
class IconButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        shared()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        shared()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        shared()
    }
    
    func shared() {
        self.tintColor = .white
        self.layer.zPosition = 3
        self.backgroundColor = .clear
        self.imageView?.contentMode = .scaleAspectFit
        self.layer.cornerRadius = 8
        self.size(CGSize(width: 48, height: 48))
        self.imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }
    
}
