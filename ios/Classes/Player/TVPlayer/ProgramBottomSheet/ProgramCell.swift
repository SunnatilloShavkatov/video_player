//
//  ProgramCell.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 21/04/22.
//

import UIKit

class ProgramCell: UITableViewCell {
    
    var programModel : TvProgram?{
        didSet{
            timeLB.text = programModel?.scheduledTime
            channelNamesLB.text = programModel?.programTitle
        }
    }
    var containerStack: UIStackView = {
        let st = UIStackView()
        st.alignment = .center
        st.axis = .horizontal
        st.distribution = .fill
        st.spacing = 20
        st.backgroundColor = .clear
        st.isUserInteractionEnabled = false
        st.translatesAutoresizingMaskIntoConstraints = false
        return st
    }()
    
    var verticalStack: UIStackView = {
        let st = UIStackView()
        st.alignment = .leading
        st.axis = .vertical
        st.distribution = .fill
        st.spacing = 10
        st.isUserInteractionEnabled = false
        st.translatesAutoresizingMaskIntoConstraints = false
        return st
    }()
    
    var hStack: UIStackView = {
        let st = UIStackView()
        st.alignment = .center
        st.axis = .horizontal
        st.distribution = .fill
        st.spacing = 10
        st.isUserInteractionEnabled = false
        st.translatesAutoresizingMaskIntoConstraints = false
        return st
    }()
    
   lazy var timeLB: UILabel = {
        let label = UILabel()
        label.text = programModel?.scheduledTime
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .darkGray
    
        return label
    }()
    
   lazy var channelNamesLB: UILabel = {
        let label = UILabel()
        label.text = programModel?.programTitle
        label.font = UIFont.systemFont(ofSize: 15)
        label.numberOfLines = 0
        label.sizeToFit()
        label.clipsToBounds = true
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.textColor = .white
        return label
    }()
    
    var circleView: UIView = {
        let view = UIView()
        view.backgroundColor = .green
        return view
    }()
    
    var progressView: UIProgressView = {
        let view = UIProgressView()
        view.trackTintColor = .white
        view.tintColor = .yellow
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.progress = 0.5
        view.isHidden = true
        return view
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
        self.backgroundColor =  .clear
        
        setUp()
        
        containerStack.snp.makeConstraints { make in
            make.edges.equalTo(self).inset(UIEdgeInsets(top: 10, left: 56,bottom: 10, right: 30))
            make.width.equalToSuperview()
        }
        
        timeLB.snp.makeConstraints { make in
            make.width.equalTo(50)
            }
        progressView.snp.makeConstraints { make in
            make.height.equalTo(0)
            make.width.equalToSuperview()
        }
    }
    
    func setUp() {
        contentView.addSubview(containerStack)
        containerStack.addArrangedSubviews(
            timeLB,
            verticalStack
        )
        
        verticalStack.addArrangedSubviews(
            hStack,
            progressView
        )
        
        hStack.addArrangedSubviews(
            channelNamesLB
        )
    }
}
extension UIStackView {
    func addArrangedSubviews(_ views: UIView...) {
        views.forEach {
            self.addArrangedSubview($0)
        }
    }
}
