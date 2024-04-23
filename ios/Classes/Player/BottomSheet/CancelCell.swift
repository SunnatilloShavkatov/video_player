//
//  CancelCell.swift
//  Runner
//
//  Created by Shavkatov Sunnatillo on 21/04/22.
//

import UIKit

class CancelCell: UITableViewCell {
    
    
    lazy var cancelView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var divider : UIView = {
        let div = UIView()
        div.backgroundColor = .gray.withAlphaComponent(0.6)
        return div
    }()
    var cancelLabel : UILabel = {
        let label = UILabel()
        label.text = "Отменить"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 15,weight: .medium)
        return label
    }()
    lazy var cancelBtn: UIImageView = {
        let imageView = UIImageView()
        let image = Svg.exit!
        imageView.image = image
        imageView.size(CGSize(width: 24, height: 24))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = false
        return imageView
    }()
    lazy var horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.addArrangedSubviews(cancelBtn, cancelLabel)
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 40
        stackView.backgroundColor = .clear
        return stackView
    }()
    lazy var verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.addArrangedSubviews(divider, horizontalStackView)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 21
        stackView.distribution = .fill
        stackView.backgroundColor = .clear
        return stackView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupView() {
        addSubview(cancelView)
        setupConstraints()
    }
    
    override var intrinsicContentSize: CGSize {
        let height = CGFloat(21)
        return CGSize(width: 200, height: height)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setupConstraints() {
        
        // Add subviews
        cancelView.addSubview(verticalStackView)
        divider.snp.makeConstraints { make in
            make.right.left.equalToSuperview()
            make.height.equalTo(1)
        }
        cancelView.snp.makeConstraints { make in
            make.height.equalTo(80)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        verticalStackView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.top.equalTo(10)
            make.left.equalTo(cancelView).offset(50)
        }
        horizontalStackView.snp.makeConstraints { make in
            make.left.equalTo(verticalStackView).offset(0)
            make.right.equalToSuperview()
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
