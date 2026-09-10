#if os(iOS)
//
//  SettingsVC.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 21/04/22.
//

import UIKit

protocol SettingDelegate {
    func settingData(leftIcon: UIImage, title: String,cnfigureLabel: String)
}

class SettingVC: UIViewController, UIGestureRecognizerDelegate {
    
    var movieController = VideoPlayerViewController()
    var delegate: QualityDelegate?
    var speedDelegate: SpeedDelegate?
    var subtitleDelegate: SubtitleDelegate?
    var subtitleSizeDelegate: SubtitleSizeDelegate?
    var speedTitle: String = "1x"
    
    var settingModel = [SettingModel]()
    
    lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.tableFooterView = UIView(frame: .zero)
        table.backgroundColor = UIColor(named: "")
        table.register(SettingCell.self,forCellReuseIdentifier: "cell")
        table.dataSource = self
        table.delegate = self
        table.allowsSelection = true
        table.separatorColor = .clear
        table.backgroundColor =  Colors.moreColor
        table.isScrollEnabled = false
        table.contentInsetAdjustmentBehavior = .never
        // .grouped adds implicit section header/footer space, which pushes the last
        // row past the sheet height calculated from the row count.
        table.sectionHeaderHeight = 0
        table.sectionFooterHeight = 0
        table.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        if #available(iOS 15.0, *) {
            table.sectionHeaderTopPadding = 0
        }
        let inset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        table.contentInset = inset
        return table
    }()
    
    
    lazy var topView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var contentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 24
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var mainStack: UIStackView = {
        let stackView = UIStackView()
        stackView.addArrangedSubviews(contentView)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 21
        stackView.distribution = .fill
        stackView.backgroundColor = .clear
        return stackView
    }()
    
    
    lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var backdropView: UIView = {
        let bdView = UIView(frame: self.view.bounds)
        bdView.backgroundColor = .clear
        return bdView
    }()
    
    let menuView :UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        view.backgroundColor = .black
        return view
    }()
    
    var menuHeight = UIScreen.main.bounds.height
    var isPresenting = false
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func cancelTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    private func calculateMenuHeight() -> CGFloat {
        let bottomInset = max(view.safeAreaInsets.bottom, 28.0)
        let rowsHeight = CGFloat(settingModel.count) * 48.0
        let topPadding: CGFloat = 8.0
        let headerPadding: CGFloat = 20.0
        let totalHeight = rowsHeight + topPadding + headerPadding + bottomInset
        let minHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 160 : 320
        let maxHeight = view.bounds.height * 0.8
        let height = min(max(totalHeight, minHeight), maxHeight)
        // Only scroll when the rows genuinely do not fit (e.g. landscape).
        tableView.isScrollEnabled = totalHeight > maxHeight
        return height
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        tableView.contentInsetAdjustmentBehavior = .never
        menuHeight = calculateMenuHeight()
        
        view.addSubview(backdropView)
        view.addSubview(menuView)
        menuView.addSubview(backView)
        backView.addSubview(mainStack)
        contentView.addSubview(tableView)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        menuView.backgroundColor = Colors.backgroundBottomSheet
        tableView.backgroundColor = .clear
        menuView.translatesAutoresizingMaskIntoConstraints = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        backdropView.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        menuHeight = calculateMenuHeight()
        let bottomInset = max(view.safeAreaInsets.bottom, 28.0)

        backView.snp.remakeConstraints { make in
            make.edges.equalTo(menuView)
        }
        mainStack.snp.remakeConstraints { make in
            make.edges.equalTo(menuView)
        }
        contentView.snp.remakeConstraints { make in
            make.edges.equalTo(mainStack)
        }
        tableView.snp.remakeConstraints { make in
            make.left.right.equalTo(view.safeAreaLayoutGuide)
            make.top.equalTo(contentView).offset(8)
            make.bottom.equalTo(menuView).offset(-bottomInset)
        }
        
        menuView.snp.remakeConstraints { make in
            make.height.equalTo(menuHeight)
            make.bottom.equalToSuperview()
            make.right.left.equalToSuperview().inset(0)
        }
    }
    
    @objc func handleTap() {
        dismiss(animated: true, completion: nil)
    }
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension SettingVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingModel.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SettingCell
        cell.model = settingModel[indexPath.row]
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < settingModel.count else { return }

        let selectedSetting = settingModel[indexPath.row]
        guard selectedSetting.isEnabled else { return }

        self.dismiss(animated: true) {
            switch selectedSetting.action {
            case .quality:
                self.delegate?.qualityBottomSheet()
            case .speed:
                self.speedDelegate?.speedBottomSheet()
            case .subtitle:
                self.subtitleDelegate?.subtitleBottomSheet()
            case .subtitleSize:
                self.subtitleSizeDelegate?.subtitleSizeBottomSheet()
            }
        }
    }
}

//MARK: Transition animation
extension SettingVC: UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning  {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 1
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        guard let toVC = toViewController else { return }
        isPresenting = !isPresenting
        
        if isPresenting == true {
            containerView.addSubview(toVC.view)
            
            menuView.frame.origin.y += menuHeight
            backdropView.alpha = 0
            
            UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseOut], animations: {
                self.menuView.frame.origin.y -= self.menuHeight
                self.backdropView.alpha = 1
            }, completion: { (finished) in
                transitionContext.completeTransition(true)
            })
        } else {
            UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseOut], animations: {
                self.menuView.frame.origin.y += self.menuHeight
                self.backdropView.alpha = 0
            }, completion: { (finished) in
                transitionContext.completeTransition(true)
            })
        }
    }
}

#endif
