//
//  SettingsVC.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 21/04/22.
//

import UIKit

protocol TVSettingDelegate {
    func settingData(leftIcon: UIImage, title: String,cnfigureLabel: String)
}

class TVSettingVC: UIViewController, UIGestureRecognizerDelegate {
    
    var resolutions: [String:String]?
    var movieController = VideoPlayerViewController()
//    var delegete: TVQualityDelegate?
//    var speedDelegate: TVSpeedDelegate?
    var speedTitle: String = "1x"
    
    var settingModel = [SettingModel]()
    
    lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.tableFooterView = UIView(frame: .zero)
        table.backgroundColor = UIColor(named: "")
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        table.register(SettingCell.self,forCellReuseIdentifier: "cell")
        table.dataSource = self
        table.delegate = self
        table.allowsSelection = true
        table.separatorColor = .clear
        table.backgroundColor =  Colors.moreColor
        table.isScrollEnabled = false
        table.contentInsetAdjustmentBehavior = .never
        let inset = UIEdgeInsets(top: 0, left: 0, bottom: -38, right: 0)
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
        view.layer.cornerRadius = 24
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var cancelBtn: UIButton = {
        let cancelBtn = UIButton()
        cancelBtn.setImage(Svg.exit!, for: .normal)
        cancelBtn.imageView?.contentMode = .scaleAspectFit
        cancelBtn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return cancelBtn
    }()
    
    
    lazy var backdropView: UIView = {
        let bdView = UIView(frame: self.view.bounds)
        bdView.backgroundColor = .clear
        return bdView
    }()
    
    let menuView :UIView = {
        let view = UIView()
        view.layer.cornerRadius = 24
        view.backgroundColor = .clear
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        tableView.contentInsetAdjustmentBehavior = .never
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0);
        if UIDevice.current.userInterfaceIdiom == .phone {
            menuHeight = 150
        }else {
            menuHeight = 180
        }
        
        view.addSubview(backdropView)
        view.addSubview(menuView)
        menuView.addSubview(backView)
        backView.addSubview(mainStack)
        contentView.addSubview(tableView)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        menuView.backgroundColor = Colors.backgroundBottomSheet
        tableView.backgroundColor = .clear
        tableView.layer.cornerRadius=24
        menuView.translatesAutoresizingMaskIntoConstraints = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        backdropView.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()        
        backView.snp.makeConstraints { make in
            make.edges.equalTo(menuView)
        }
        mainStack.snp.makeConstraints { make in
            make.width.equalTo(menuView)
            make.height.equalTo(menuView)
            make.top.equalTo(menuView)
            make.edges.equalTo(menuView)
        }
        contentView.snp.makeConstraints { make in
            make.width.equalTo(mainStack)
            make.height.equalTo(mainStack).multipliedBy(1)
        }
        tableView.snp.makeConstraints { make in
            make.left.right.equalTo(view.safeAreaLayoutGuide)
            make.top.equalTo(contentView).offset(-16)
            make.width.equalTo(contentView).offset(50)
            make.height.equalTo(125)
        }
        
        menuView.snp.makeConstraints { make in
            make.height.equalTo(menuHeight)
            make.bottom.equalToSuperview()
            make.right.left.equalToSuperview().inset(0)
        }
        
    }
    
    @objc func handleTap() {
        dismiss(animated: true, completion: nil)
    }
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        print("Tapped")
        self.dismiss(animated: true, completion: nil)
    }
}

extension TVSettingVC: UITableViewDataSource, UITableViewDelegate {
    
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
//        if (indexPath.row == 0) {
//            self.dismiss(animated: true) {
//                self.speedDelegate?.speedBottomSheet()
//            }
//        } else {
//            self.dismiss(animated: true) {
//                self.delegete?.qualityBottomSheet()
//            }
//        }
    }
}

//MARK: Transition animation
extension TVSettingVC: UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning  {
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

