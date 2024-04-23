//
//  TitleLabel.swift
//  Pods
//
//  Created by Udevs on 22/10/22.
//

import Foundation

class TitleLabel :UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        self.textColor = .red
        self.textColor = .white
        self.textAlignment = .center
        self.numberOfLines = 2
        self.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        self.isHidden = true
    }
}
