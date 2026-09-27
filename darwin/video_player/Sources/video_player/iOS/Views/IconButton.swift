#if os(iOS)
//
//  PlayButton.swift
//  video_player
//
//  Created by Sunnatillo Shavkatov on 23/10/22.
//

import Foundation
import UIKit

@IBDesignable
class IconButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        shared()
    }

    /// Icon button with an optional symmetric image inset (default inset is 12).
    convenience init(icon: UIImage?, inset: CGFloat? = nil) {
        self.init(frame: .zero)
        setImage(icon, for: .normal)
        if let inset {
            imageEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        }
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
        self.snp.makeConstraints { make in
            make.width.equalTo(48)
            make.height.equalTo(48)
        }
        self.imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }
}

#endif
