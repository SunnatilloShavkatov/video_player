//
//  SeasonSelectionCell.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 21/04/22.
//

import Foundation
import UIKit


class SeasonSelectionCell : UITableViewCell{
    
    var title : String?{
        didSet{
            headerTitle.text = title
        }
    }
    var isSelectedItem: Bool?{
        didSet{
            checkIcon.isHidden = !(isSelectedItem ?? false)
        }
    }
    
    lazy var checkIcon: UIImageView = {
        let imageView = UIImageView()
        let image = UIImage(named: "ic_done",in: Bundle(for: SwiftUdevsVideoPlayerPlugin.self),compatibleWith: nil)
        imageView.image = image
        imageView.tintColor = Colors.white
        imageView.size(CGSize(width: 24, height: 24))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = false
        return imageView
    }()
    
    lazy var headerTitle: UILabel = {
        let headerTitle = UILabel()
        headerTitle.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        headerTitle.text = title
        headerTitle.textColor = .white
        headerTitle.textAlignment = .left
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        return headerTitle
    }()
    
    
    lazy var headerView: UIView = {
        let headerView = UIView()
        headerView.addSubview(headerTitle)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
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
        addSubview(headerView)
        setupLayout()
    }
    
    private func setupLayout() {
        headerView.addSubview(headerTitle)
        headerView.addSubview(checkIcon)
        
        headerView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(contentView)
        }
        headerTitle.snp.makeConstraints { make in
            make.left.equalTo(headerView).offset(74)
        }
    }
}
