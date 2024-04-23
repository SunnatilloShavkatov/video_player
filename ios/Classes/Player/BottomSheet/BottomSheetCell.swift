import Foundation
import UIKit

class BottomSheetCell : UITableViewCell{
    
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
        let image = Svg.done!
        imageView.image = image
        imageView.size(CGSize(width: 32, height: 32))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white.withAlphaComponent(0.5)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    lazy var headerTitle: UILabel = {
        let headerTitle = UILabel()
        headerTitle.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        headerTitle.text = title
        headerTitle.textColor = .white
        headerTitle.textAlignment = .left
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        return headerTitle
    }()
    
    var horizontalStack: UIStackView = {
        let st = UIStackView()
        st.alignment = .leading
        st.axis = .horizontal
        st.distribution = .fill
        st.spacing = 20
        st.isUserInteractionEnabled = true
        st.backgroundColor = .clear
        st.translatesAutoresizingMaskIntoConstraints = false
        return st
    }()
    
    lazy var headerView: UIView = {
        let headerView = UIView()
        headerView.addSubview(headerTitle)
        headerView.addSubview(checkIcon)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()
    
    lazy var mainVerticalStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [headerView])
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
            
            headerTitle.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            headerTitle.leadingAnchor.constraint(equalTo: headerView.leadingAnchor,constant: 16),
            
            //layout forwardIcon in headerView
            checkIcon.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            checkIcon.trailingAnchor.constraint(equalTo: headerView.trailingAnchor,constant: -12),
            checkIcon.widthAnchor.constraint(equalToConstant: 22),
            checkIcon.heightAnchor.constraint(equalToConstant: 22),
            
            //pin headerView to top
            mainVerticalStack.topAnchor.constraint(equalTo: topAnchor),
            mainVerticalStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainVerticalStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainVerticalStack.heightAnchor.constraint(equalToConstant: 44),
            
        ])
    }
}
