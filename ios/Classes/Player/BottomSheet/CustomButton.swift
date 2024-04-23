//
//  CustomButton.swift
//  Runner
//
//  Created by Shavaktov Sunnatillo on 21/04/22.
//
import UIKit

class VerticalButton: UIButton {
    var highlightedColor: UIColor?
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? highlightedColor?.withAlphaComponent(0.5) : highlightedColor?.withAlphaComponent(0.2)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentHorizontalAlignment = .left
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        centerButtonImageAndTitle()
    }
    
    private func centerButtonImageAndTitle() {
        let titleSize = self.titleLabel?.frame.size ?? .zero
        let imageSize = self.imageView?.frame.size ?? .zero
        let spacing: CGFloat = 6.0
        self.imageEdgeInsets = UIEdgeInsets(top: -(titleSize.height + spacing),left: 0, bottom: 0, right:  -titleSize.width)
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageSize.width, bottom: -(imageSize.height + spacing), right: 0)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        self.titleLabel?.textColor = highlightedColor
        self.tintColor = highlightedColor
        self.backgroundColor = highlightedColor?.withAlphaComponent(0.2)
    }
}
