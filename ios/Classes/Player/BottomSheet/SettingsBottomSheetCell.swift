//
//  SettingsBottomSheetCell.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 21/04/22.
//

import Foundation
import UIKit
class SettingsBottomSheetCell : UITableViewCell{
    
    var model : SettingsBottomSheetModel?{
        didSet{
            headerImage.image = UIImage(named: model!.icon)
            headerTitle.text = model?.title
            currentTitle.text = model?.currentLabel
        }
    }
    
    lazy var forwardIcon: UIImageView = {
        let imageView = UIImageView()
        let image = Svg.right!
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white.withAlphaComponent(0.5)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy var headerImage : UIImageView = {
        let imageView = UIImageView()
        let image = UIImage(named: model?.icon ?? "")
        imageView.image = image
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy var headerTitle: UILabel = {
        let headerTitle = UILabel()
        headerTitle.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        headerTitle.text = model?.title
        headerTitle.textColor = .white
        headerTitle.textAlignment = .left
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        return headerTitle
    }()
    
    lazy var currentTitle: UILabel = {
        let headerTitle = UILabel()
        headerTitle.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        headerTitle.text = model?.currentLabel
        headerTitle.textColor = .white
        headerTitle.textAlignment = .right
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        return headerTitle
    }()
    
    lazy var divider : UIView = {
        let div = UIView()
        div.backgroundColor = .gray.withAlphaComponent(0.6)
        return div
    }()
    
    lazy var titleImageStackView :UIStackView = {
        let stack = UIStackView(
            arrangedSubviews: [headerImage, headerTitle]
        )
        stack.axis = .horizontal
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    lazy var currentTitleIconStackView : UIStackView = {
        let stack = UIStackView(
            arrangedSubviews: [currentTitle, forwardIcon]
        )
        stack.axis = .horizontal
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    lazy var headerView: UIView = {
        let headerView = UIView()
        headerView.addSubview(titleImageStackView)
        headerView.addSubview(currentTitleIconStackView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()
    
    lazy var mainVerticalStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [headerView,divider])
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupView()
    }
    
    
    override var intrinsicContentSize: CGSize {
        let height = CGFloat(21)
        return CGSize(width: 200, height: height)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(mainVerticalStack)
        setupLayout()
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            // image to headerView
            
            titleImageStackView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleImageStackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor,constant: 20),
            
            //layout forwardIcon in headerView
            currentTitleIconStackView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            currentTitleIconStackView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor,constant: -12),
            forwardIcon.widthAnchor.constraint(equalToConstant: 22),
            forwardIcon.heightAnchor.constraint(equalToConstant: 22),
            
            // header image size
            headerImage.widthAnchor.constraint(equalToConstant: 24),
            headerImage.heightAnchor.constraint(equalToConstant: 24),
            
            // divider size
            divider.heightAnchor.constraint(equalToConstant: 0.7),
            
            //pin headerView to top
            mainVerticalStack.topAnchor.constraint(equalTo: topAnchor),
            mainVerticalStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainVerticalStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainVerticalStack.heightAnchor.constraint(equalToConstant: 44),
            
        ])
    }
}

