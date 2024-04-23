//
//  SettingsCell.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 21/04/22.
//


import UIKit
import SnapKit

class SettingCell: UITableViewCell {
    
    var model: SettingModel?  {
        didSet{
            leftIcon.image = model?.leftIcon
            leftTitle.text = model?.title ?? ""
            configureLabel.text = model?.configureLabel ?? ""
        }
    }
    var containerStack: UIStackView = {
        let st = UIStackView()
        st.alignment = .center
        st.axis = .horizontal
        st.distribution = .equalSpacing
        st.spacing = 27
        st.backgroundColor = .clear
        st.isUserInteractionEnabled = false
        st.translatesAutoresizingMaskIntoConstraints = false
        return st
    }()
    lazy var leftStack: UIStackView = {
        let st = UIStackView()
        st.alignment = .leading
        st.axis = .horizontal
        st.distribution = .fill
        st.spacing = 27
        st.backgroundColor = .clear
        st.isUserInteractionEnabled = false
        st.translatesAutoresizingMaskIntoConstraints = false
        return st
    }()
    lazy var rightStack: UIStackView = {
        let st = UIStackView()
        st.alignment = .trailing
        st.axis = .horizontal
        st.distribution = .fillProportionally
        st.spacing = 12
        st.backgroundColor = .clear
        st.isUserInteractionEnabled = false
        st.translatesAutoresizingMaskIntoConstraints = false
        return st
    }()
    
    lazy var leftIcon: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.image = model?.leftIcon
        return image
    }()
    
    lazy var leftTitle: UILabel = {
        let label = UILabel()
        label.text = model?.title
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 15,weight: .regular)
        return label
    }()
    
    lazy var rightIcon: UIImageView = {
        let image = UIImageView()
        image.backgroundColor = .clear
        image.sizeToFit()
        image.image = Svg.right!
        return image
    }()
    
    lazy var configureLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textAlignment = .right
        label.text = model?.configureLabel
        label.textColor = UIColor(rgb: 0xff9D9D9D)
        label.font = UIFont.systemFont(ofSize: 15,weight: .regular)
        return label
    }()
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Layout
        self.backgroundColor = .clear
        
        setUp()
        containerStack.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(48)
            //            make.bottom.equalTo(self.safeAreaLayoutGuide).offset(0)
            make.right.equalTo(self.safeAreaLayoutGuide).offset(-16)
            make.left.equalTo(self.safeAreaLayoutGuide).offset(16)
            make.top.equalToSuperview()
        }
        leftIcon.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        rightIcon.snp.makeConstraints { make in
            make.width.height.equalTo(20)
        }
        leftStack.snp.makeConstraints { make in
            make.width.equalTo(200)
            make.top.equalTo(containerStack).offset(14)
            make.bottom.equalTo(containerStack).offset(-14)
            make.left.equalTo(containerStack)
        }
        rightStack.snp.makeConstraints { make in
            make.width.equalTo(172)
            make.top.equalTo(containerStack).offset(14)
            make.bottom.equalTo(containerStack).offset(-14)
            make.right.equalTo(containerStack)
        }
        configureLabel.snp.makeConstraints { make in
            make.width.equalTo(50)
        }
    }
    
    func setUp() {
        contentView.addSubview(containerStack)
        containerStack.addArrangedSubviews(leftStack,rightStack)
        leftStack.addArrangedSubviews(leftIcon,leftTitle)
        rightStack.addArrangedSubviews(configureLabel,rightIcon)
    }
}

