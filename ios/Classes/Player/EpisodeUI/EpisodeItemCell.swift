//
//  EpisodeItemCell.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 21/04/22.
//
import UIKit
import SnapKit

class EpisodeCollectionCell: UICollectionViewCell {
    
    var episodes : Movie? {
        didSet {
            titleLbl.text = episodes?.title ?? ""
            descriptionLabel.text = episodes?.description ?? ""
            durationLbl.text = VGPlayerUtils.getTimeIntString(from: episodes?.duration ?? 0)
        }
    }
    
    var containerStack: UIStackView = {
        let st = UIStackView()
        st.alignment = .leading
        st.axis = .vertical
        st.distribution = .fill
        st.spacing = 8
        st.backgroundColor = .clear
        st.isUserInteractionEnabled = true
        st.translatesAutoresizingMaskIntoConstraints = false
        return st
    }()
    
    var descriptionView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    var episodeImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "image.png")
        image.backgroundColor = .clear
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.cornerRadius = 4
        return image
    }()
    
    var playIcon: UIImageView = {
        let image = UIImageView()
        image.image = Svg.serialPlay!
        image.backgroundColor = .clear
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.cornerRadius = 16
        return image
    }()
    
    lazy var titleLbl: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = episodes?.title
        label.textColor = .white
        label.backgroundColor = .clear
        label.font = UIFont.systemFont(ofSize: 15,weight: .semibold)
        return label
    }()
    
   lazy var durationLbl: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = VGPlayerUtils.getTimeIntString(from: episodes?.duration ?? 0)
        label.textColor = UIColor(rgb: 0xFF9D9D9D)
        label.backgroundColor = .clear
        label.font = UIFont.systemFont(ofSize: 11,weight: .medium)
        return label
    }()
    
     lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = episodes?.description
        label.textColor = UIColor(rgb: 0xFF9D9D9D)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.numberOfLines = 3
        label.sizeToFit()
        label.backgroundColor = .clear
        label.font = UIFont.systemFont(ofSize: 11,weight: .medium)
        return label
    }()
    
    override init(frame: CGRect) {
            super.init(frame: .zero)
        contentView.addSubview(containerStack)
        contentView.backgroundColor = .clear
        containerStack.addArrangedSubviewss(episodeImage,titleLbl,durationLbl,descriptionView,playIcon)
        setupUI()
        episodeImage.addSubview(playIcon)
    }
        
    func setupUI(){
        playIcon.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.top.equalTo(episodeImage).offset(36)
            make.centerY.equalTo(episodeImage)
            make.centerX.equalTo(episodeImage)
        }
        containerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        episodeImage.snp.makeConstraints { make in
            make.height.equalTo(168)
            make.width.equalTo(containerStack)
            make.top.left.right.equalTo(containerStack)
        }
        titleLbl.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(116)
            make.left.right.equalTo(containerStack)
            make.height.equalTo(20)
        }
        durationLbl.snp.makeConstraints { make in
            make.left.right.equalTo(containerStack).offset(0)
            make.height.equalTo(20)
        }
        descriptionView.snp.makeConstraints { make in
            make.left.right.equalTo(containerStack)
        }
        
        descriptionView.addSubview(descriptionLabel)
        
        descriptionLabel.snp.makeConstraints { make in
            make.width.equalTo(descriptionView)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIStackView {
    func addArrangedSubviewss(_ views: UIView...) {
        views.forEach {
            self.addArrangedSubview($0)
        }
    }
}
