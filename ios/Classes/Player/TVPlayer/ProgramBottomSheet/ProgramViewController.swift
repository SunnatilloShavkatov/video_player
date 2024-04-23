//
//  ProgramViewController.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 21/04/22.
//

import UIKit
import SnapKit



class ProgramViewController: UIViewController {
    
    var programInfo = [ProgramInfo]()
    
    lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.tableFooterView = UIView(frame: .zero)
        table.backgroundColor = Colors.mainBackground
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        table.register(ProgramCell.self,forCellReuseIdentifier: "cell")
        table.dataSource = self
        table.delegate = self
        table.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        table.separatorColor = .gray
        table.contentInsetAdjustmentBehavior = .never
        let inset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        table.contentInset = inset
        return table
    }()
    
    lazy var backdropView: UIView = {
        let bdView = UIView(frame: self.view.bounds)
        bdView.backgroundColor = .clear
        return bdView
    }()
    
    lazy var mainVerticalView: UIStackView = {
        let stackView = UIStackView()
        stackView.addArrangedSubviews(tableView, cancelView)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 21
        stackView.distribution = .fill
        stackView.backgroundColor = Colors.backgroudColor
        return stackView
    }()
    
    lazy var divider : UIView = {
        let div = UIView()
        div.backgroundColor = .gray.withAlphaComponent(0.6)
        return div
    }()

    lazy var cancelView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var cancelBtn: UIButton = {
        let cancelBtn = UIButton()
        cancelBtn.backgroundColor = .clear
        cancelBtn.setImage(Svg.exit!, for: .normal)
        cancelBtn.imageView?.contentMode = .scaleAspectFit
        cancelBtn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return cancelBtn
    }()
    
    lazy var tabBarYesterday: UIButton = {
        let tabBarButton = UIButton()
        tabBarButton.setTitle("Yesterday", for: .normal)
        return tabBarButton
    }()
    lazy var tabBarToday: UIButton = {
        let tabBarButton = UIButton()
        tabBarButton.setTitle("Today", for: .normal)
        return tabBarButton
    }()
    lazy var tabBarTomorrow: UIButton = {
        let tabBarButton = UIButton()
        tabBarButton.setTitle("Tomorrow", for: .normal)
        return tabBarButton
    }()
    
    lazy var horizontalTabs: UIStackView = {
        let stackView = UIStackView()
        stackView.addArrangedSubviews(tabBarYesterday, tabBarToday,tabBarTomorrow)
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        stackView.backgroundColor = .red
        
        return stackView
    }()
    lazy var vStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.addArrangedSubviews(horizontalTabs, tableView)
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 21
        stackView.distribution = .fill
        stackView.backgroundColor = .clear
        return stackView
    }()
    
    lazy var verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.addArrangedSubviews(divider, horizontalStackView)
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 21
        stackView.distribution = .fill
        stackView.backgroundColor = .clear
        return stackView
    }()
    
    lazy var horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.addArrangedSubviews(cancelBtn)
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 29
        stackView.backgroundColor = .clear
        return stackView
    }()
    
    lazy var menuView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        view.backgroundColor = Colors.mainBackground
        return view
    }()
    
    var menuHeight =  UIScreen.main.bounds.height * 0.80
    var isPresenting = false
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if UIDevice.current.userInterfaceIdiom == .phone {
            if(UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight){
                menuHeight =  300
            } else {
                menuHeight =  500
            }
            print("Orientation isLandscape\(UIDevice.current.orientation.isLandscape) \(menuHeight)")
        } else {
            if programInfo.isEmpty {
                menuHeight =  UIScreen.main.bounds.height * 0.75
            }else {
                menuHeight = 210
            }
        }
    }
    
    override func viewDidLoad() {
        if UIDevice.current.userInterfaceIdiom == .phone {
            if programInfo.isEmpty {
                menuHeight =  UIScreen.main.bounds.height * 0.75
            } else {
                if(UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight){
                    menuHeight =  300
                } else {
                    menuHeight =  500
                }
            }
        } else {
            if programInfo.isEmpty {
                menuHeight =  UIScreen.main.bounds.height * 0.75
            } else {
                menuHeight = 210
            }
        }
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(backdropView)
        view.addSubview(menuView)
        menuView.addSubview(tableView)
        menuView.backgroundColor = .white
        tableView.sectionFooterHeight = 0
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.sectionHeaderHeight = 0
        var frame = CGRect.zero
        frame.size.height = .leastNormalMagnitude
        tableView.tableHeaderView = UIView(frame: frame)
        menuView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        backdropView.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            tableView.snp.makeConstraints { make in
                make.left.equalTo(menuView)
                make.right.equalTo(menuView)
                make.top.equalTo(menuView).offset(0)
                make.height.equalTo(menuView)
            }
        } else {
            tableView.snp.makeConstraints { make in
                make.left.equalTo(menuView).offset(0)
                make.right.equalTo(menuView)
                make.top.equalTo(menuView).offset(0)
                make.height.equalTo(menuView).multipliedBy(0.7)
            }
        }

        menuView.snp.makeConstraints { make in
            make.height.equalTo(menuHeight)
            make.bottom.equalToSuperview().inset(0)
            make.right.left.equalToSuperview()
        }
        cancelBtn.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
    }
    @objc func handleTap() {
        dismiss(animated: true, completion: nil)
    }
    @objc func cancelTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ProgramViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return programInfo[section].tvPrograms?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ProgramCell
        cell.selectionStyle = .none
        if !(programInfo[indexPath.section].day.isEmpty) {
            cell.timeLB.text = programInfo[indexPath.section].tvPrograms?[indexPath.row].scheduledTime ?? ""
                cell.timeLB.textColor = .white
                cell.timeLB.font = UIFont.boldSystemFont(ofSize: 16)
            cell.channelNamesLB.textColor = .white
            cell.circleView.backgroundColor = .green
            cell.channelNamesLB.text = programInfo[indexPath.section].tvPrograms?[indexPath.row].programTitle ?? ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return programInfo.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !(programInfo.isEmpty)  {
            if section == 0 && !(programInfo[0].day.isEmpty){
                let headerView = UIView.init(frame: CGRect.init(x: 16, y: 0, width: tableView.frame.width, height: 80))
                headerView.backgroundColor = .clear

                let label = UILabel()
                label.font = UIFont.boldSystemFont(ofSize: 17)
                label.text = programInfo[0].day
                label.textColor = .white

                let button = UIButton(type: .custom)
                button.setImage(Svg.exit!, for: .normal)
                button.imageView?.contentMode = .scaleAspectFill
                button.tintColor = .white

                let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
                button.addGestureRecognizer(tap)

                headerView.addSubview(label)
                headerView.addSubview(button)

                label.snp.makeConstraints { make in
                    make.left.equalToSuperview().inset(56)
                    make.centerY.equalToSuperview()
                }

                button.snp.makeConstraints { make in
                    make.right.equalToSuperview().inset(50)
                    make.centerY.equalToSuperview()
                    make.width.equalTo(30)
                }
                return headerView
            } else if section >= 1  && !programInfo[0].day.isEmpty {
                let headerView = UIView.init(frame: CGRect.init(x: 16, y: 0, width: tableView.frame.width, height: 80))
                headerView.backgroundColor =  .clear
                let label = UILabel()
                label.font = UIFont.boldSystemFont(ofSize: 17)
                label.text =  programInfo[section].day
                label.textColor = .white
                headerView.addSubview(label)
                label.snp.makeConstraints { make in
                    make.left.equalToSuperview().inset(56)
                    make.centerY.equalToSuperview()
                }
                return headerView
            }
        }
        return UIView()
    }
    
}

//MARK: Transition animation
extension ProgramViewController: UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning  {
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
            
            menuView.frame.origin.y +=  menuHeight
            backdropView.alpha = 0
            
            UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseOut], animations: {
                self.menuView.frame.origin.y -=  self.menuHeight
                self.backdropView.alpha = 1
            }, completion: { (finished) in
                transitionContext.completeTransition(true)
            })
        } else {
            UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseOut], animations: {
                self.menuView.frame.origin.y +=  self.menuHeight
                self.backdropView.alpha = 0
            }, completion: { (finished) in
                transitionContext.completeTransition(true)
            })
        }
    }
}
