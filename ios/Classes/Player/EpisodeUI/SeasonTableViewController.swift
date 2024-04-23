//
//  SeasonTableViewController.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 21/04/22.
//

import Foundation
import UIKit
import SnapKit

enum SeasonBottomSheetType{
    case quality, speed, subtitle, audio,season
}

protocol BottomSheetCellDelegateSeason {
    func onBottomSheetCellTapped(index : Int, type : SeasonBottomSheetType)
}

class SeasonSelectionController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var items = [Season]()
    var labelText : String?
    var closeText : String = ""
    var selectedIndex = 0
    var episodeIndex: Int = 0
    var seasonIndex: Int = 0
    var cellDelegate : BottomSheetCellDelegateSeason?
    var bottomSheetType = SeasonBottomSheetType.season
    
    lazy var labelView : UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
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
        label.text = ""
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 15,weight: .medium)
        return label
    }()
    lazy var cancelBtn: UIButton = {
        let cancelBtn = UIButton()
        cancelBtn.setImage(Svg.exit!, for: .normal)
        cancelBtn.imageView?.contentMode = .scaleAspectFit
        cancelBtn.imageEdgeInsets = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        cancelBtn.size(CGSize(width: 24, height: 24))
        cancelBtn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return cancelBtn
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
    
    lazy var contentTableView: UITableView = {
        let tableView = UITableView()
        tableView.tintColor = .clear
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.moreColor
        view.clipsToBounds = true
        return view
    }()
    
    lazy var mainVerticalStack : UIStackView = {
        let stack = UIStackView(arrangedSubviews: [labelView,contentTableView])
        stack.spacing = 0
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    let maxDimmedAlpha: CGFloat = 0.6
    
    lazy var dimmedView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = maxDimmedAlpha
        return view
    }()
    
    // Constants
    var defaultHeight: CGFloat = UIScreen.main.bounds.height
    var dismissibleHeight: CGFloat = 200
    let maximumContainerHeight: CGFloat = UIScreen.main.bounds.height
    // keep current new height, initial is default height
    var currentContainerHeight: CGFloat = 250
    
    // Dynamic container constraint
    var containerViewHeightConstraint: NSLayoutConstraint?
    var containerViewBottomConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cancelLabel.text = closeText
        defaultHeight = CGFloat((items.count * 44) + 100)
        dismissibleHeight = defaultHeight - 50
        contentTableView.delegate = self
        contentTableView.dataSource = self
        contentTableView.alwaysBounceVertical = false
        contentTableView.isScrollEnabled = false
        contentTableView.tableFooterView = cancelView
        self.contentTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        contentTableView.register(BottomSheetCell.self, forCellReuseIdentifier: "BottomSheetCell")
        setupView()
        setupConstraints()
        // tap gesture on dimmed view to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleCloseAction))
        dimmedView.addGestureRecognizer(tapGesture)
        //        setupPanGesture()
    }
    
    @objc func handleCloseAction() {
        animateDismissView()
    }
    @objc func cancelTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateShowDimmedView()
        animatePresentContainer()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BottomSheetCell") as! BottomSheetCell
        if bottomSheetType == .speed{
            cell.title = "\(items[indexPath.row])x"
        } else {
            cell.title =  (items[indexPath.row].title)
        }
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.isSelectedItem = indexPath.row == selectedIndex
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        animateDismissView()
        cellDelegate?.onBottomSheetCellTapped(index: indexPath.row, type : bottomSheetType)
        tableView.reloadData()
    }
    
    func setupView() {
        view.backgroundColor = .clear
    }
    
    func setupConstraints() {
        // Add subviews
        view.addSubview(dimmedView)
        view.addSubview(containerView)
        containerView.addSubview(mainVerticalStack)
        containerView.addSubview(cancelView)
        cancelView.addSubview(verticalStackView)
        dimmedView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        labelView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set static constraints
        NSLayoutConstraint.activate([
            // set dimmedView edges to superview
            dimmedView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        containerView.snp.makeConstraints({ make in
            make.left.right.equalToSuperview()
        })
        divider.snp.makeConstraints { make in
            make.right.left.equalToSuperview()
            make.height.equalTo(1)
        }
        // main stackView
        mainVerticalStack.snp.makeConstraints({ make in
            make.top.equalTo(containerView)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
            make.leading.equalTo(containerView.safeAreaLayoutGuide)
            make.trailing.equalTo(containerView.safeAreaLayoutGuide)
        })
        labelView.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.left.right.equalToSuperview()
        }
        cancelView.snp.makeConstraints { make in
            make.height.equalTo(80)
            make.right.left.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        verticalStackView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.top.equalTo(24)
            make.left.right.equalToSuperview()
        }
        horizontalStackView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview()
        }
        containerViewHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: defaultHeight)
        containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: defaultHeight)
        // Activate constraints
        containerViewHeightConstraint?.isActive = true
        containerViewBottomConstraint?.isActive = true
    }
    
    
    //MARK: - BottomSheet Animation Part
    func setupPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(gesture:)))
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        view.addGestureRecognizer(panGesture)
    }
    
    @objc func handlePanGesture(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        // Drag to top will be minus value and vice versa
        print("Pan gesture y offset: \(translation.y)")
        
        // Get drag direction
        _ = translation.y > 0
        
        // New height is based on value of dragging plus current container height
        let newHeight = currentContainerHeight - translation.y
        
        // Handle based on gesture state
        switch gesture.state {
        case .changed:
            // This state will occur when user is dragging
            if newHeight < defaultHeight {
                // Keep updating the height constraint
                containerViewHeightConstraint?.constant = newHeight
                // refresh layout
                view.layoutIfNeeded()
            }
        case .ended:
            // This happens when user stop drag,
            // so we will get the last height of container
            
            // Condition 1: If new height is below min, dismiss controller
            if newHeight < dismissibleHeight {
                self.animateDismissView()
            }
            else if newHeight < defaultHeight {
                // Condition 2: If new height is below default, animate back to default
                animateContainerHeight(defaultHeight)
            }
            
        default:
            break
        }
    }
    
    func animateContainerHeight(_ height: CGFloat) {
        UIView.animate(withDuration: 0.4) {
            // Update container height
            self.containerViewHeightConstraint?.constant = height
            // Call this to trigger refresh constraint
            self.view.layoutIfNeeded()
        }
        // Save current height
        currentContainerHeight = height
    }
    
    // MARK: Present and dismiss animation
    func animatePresentContainer() {
        // update bottom constraint in animation block
        UIView.animate(withDuration: 0.3) {
            self.containerViewBottomConstraint?.constant = 0
            // call this to trigger refresh constraint
            self.view.layoutIfNeeded()
        }
    }
    
    func animateShowDimmedView() {
        dimmedView.alpha = 0
        UIView.animate(withDuration: 0.4) {
            self.dimmedView.alpha = self.maxDimmedAlpha
        }
    }
    
    func animateDismissView() {
        // hide blur view
        dimmedView.alpha = maxDimmedAlpha
        UIView.animate(withDuration: 0.4) {
            self.dimmedView.alpha = 0
        } completion: { _ in
            // once done, dismiss without animation
            self.dismiss(animated: false)
        }
        // hide main view by updating bottom constraint in animation block
        UIView.animate(withDuration: 0.3) {
            self.containerViewBottomConstraint?.constant = self.defaultHeight
            // call this to trigger refresh constraint
            self.view.layoutIfNeeded()
        }
    }
}
