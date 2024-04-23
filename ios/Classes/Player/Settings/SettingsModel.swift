//
//  SettingsModel.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 21/04/22.
//


import UIKit

struct SettingModel {
    var title,configureLabel: String
    var leftIcon : UIImage
    
    init(leftIcon: UIImage,title: String, configureLabel: String){
        self.leftIcon = leftIcon
        self.title = title
        self.configureLabel = configureLabel
    }
}
