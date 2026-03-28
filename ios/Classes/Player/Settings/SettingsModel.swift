//
//  SettingsModel.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 21/04/22.
//


import UIKit

enum SettingAction {
    case quality
    case speed
    case subtitle
}

struct SettingModel {
    var title,configureLabel: String
    var leftIcon : UIImage
    var action: SettingAction
    var isEnabled: Bool
    
    init(leftIcon: UIImage, title: String, configureLabel: String, action: SettingAction, isEnabled: Bool = true) {
        self.leftIcon = leftIcon
        self.title = title
        self.configureLabel = configureLabel
        self.action = action
        self.isEnabled = isEnabled
    }
}
