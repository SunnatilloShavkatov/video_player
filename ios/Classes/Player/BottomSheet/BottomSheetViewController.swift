//
//  BottomSheetViewController.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 21/04/22.
//

import Foundation
import UIKit

enum BottomSheetType{
    case quality, speed, subtitle, audio
}

protocol BottomSheetCellDelegate{
    func onBottomSheetCellTapped(index : Int, type : BottomSheetType)
}

extension String {
    func capitalizingFirstLetter() -> String {
        if self.count != 0 {
            return prefix(1).capitalized + dropFirst()
        }else{
            return self
        }
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}

class BottomSheetViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var items = [String]()
    var labelText : String?
    var selectedIndex = 0
    var cellDelegate : BottomSheetCellDelegate?
    var bottomSheetType = BottomSheetType.quality
    
    // define lazy views
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = labelText
        label.font = .boldSystemFont(ofSize: 17)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var labelView : UIView = {
        let view = UIView()
        view.addSubview(titleLabel)
        return view
    }()
    
    lazy var cancelBtn: UIButton = {
        let cancelBtn = UIButton()
        cancelBtn.setImage(Svg.exit!, for: .normal)
        cancelBtn.size(CGSize(width: 48, height: 48))
        cancelBtn.imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        cancelBtn.imageView?.contentMode = .scaleAspectFit
        cancelBtn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return cancelBtn
    }()
    
    lazy var contentStackView: UIStackView = {
        let spacer = UIView()
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.backgroundColor = Colors.backgroundBottomSheet
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
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        return view
    }()
    
    lazy var horizontalStack : UIStackView = {
        let stack = UIStackView(arrangedSubviews: [cancelBtn,labelView])
        stack.axis = .horizontal
        stack.backgroundColor = .clear
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    
    lazy var mainVerticalStack : UIStackView = {
        let stack = UIStackView(arrangedSubviews: [horizontalStack,contentTableView])
        stack.spacing = 16
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    let maxDimmedAlpha: CGFloat = 0.6
    
    lazy var dimmedView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.alpha = maxDimmedAlpha
        return view
    }()
    
    // Constants
    var defaultHeight: CGFloat =  UIScreen.main.bounds.height
    var dismissibleHeight: CGFloat = 200
    let maximumContainerHeight: CGFloat = UIScreen.main.bounds.height
    // keep current new height, initial is default height
    var currentContainerHeight: CGFloat = 250
    
    // Dynamic container constraint
    var containerViewHeightConstraint: NSLayoutConstraint?
    var containerViewBottomConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if bottomSheetType != .speed {
            defaultHeight = 380
        } else {
            defaultHeight = 340
        }
        dismissibleHeight = UIScreen.main.bounds.height
        contentTableView.delegate = self
        contentTableView.dataSource = self
        contentTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        containerView.backgroundColor = Colors.backgroundBottomSheet
        contentTableView.register(BottomSheetCell.self, forCellReuseIdentifier: "BottomSheetCell")
        view.backgroundColor = .clear
        setupConstraints()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleCloseAction))
        dimmedView.addGestureRecognizer(tapGesture)
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
        var cell = tableView.dequeueReusableCell(withIdentifier: "BottomSheetCell") as! BottomSheetCell
        if bottomSheetType == .speed {
            cell.title = "\(items[indexPath.row])x"
        } else {
            cell.title = items[indexPath.row]
            cell.title?.capitalizeFirstLetter()
        }
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.isSelectedItem = indexPath.row == selectedIndex
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        animateDismissView()
        cellDelegate?.onBottomSheetCellTapped(index: indexPath.row, type : bottomSheetType)
    }
    
    func setupConstraints() {
        // Add subviews
        view.addSubview(dimmedView)
        view.addSubview(containerView)
        containerView.addSubview(mainVerticalStack)
        dimmedView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        labelView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set static constraints
        NSLayoutConstraint.activate([
            // set dimmedView edges to superview
            dimmedView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // set container static constraint (trailing & leading)
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // main stackView
            mainVerticalStack.topAnchor.constraint(equalTo: containerView.topAnchor),
            mainVerticalStack.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            mainVerticalStack.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor,constant: 16),
            mainVerticalStack.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor,constant: -16),
            labelView.heightAnchor.constraint(equalToConstant: 32)
            
        ])
        horizontalStack.snp.makeConstraints { make in
            make.width.equalTo(mainVerticalStack)
            make.height.equalTo(50)
            make.top.equalTo(mainVerticalStack).offset(16)
            
        }
        titleLabel.snp.makeConstraints { make in
            make.width.equalTo(150)
            make.centerX.equalTo(horizontalStack)
            make.centerY.equalTo(horizontalStack)
        }
        cancelBtn.snp.makeConstraints { make in
            make.left.equalTo(horizontalStack)
            make.width.equalTo(50)
        }
        containerViewHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: defaultHeight)
        containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: defaultHeight)
        // Activate constraints
        containerViewHeightConstraint?.isActive = true
        containerViewBottomConstraint?.isActive = true
    }
    
    
    func setupPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(gesture:)))
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        view.addGestureRecognizer(panGesture)
    }
    
    // MARK: Pan gesture handler
    //        @objc func handlePanGesture(gesture: UIPanGestureRecognizer) {}
    @objc func handlePanGesture(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        // Drag to top will be minus value and vice versa
        print("Pan gesture y offset: \(translation.y)")
        
        // Get drag direction
        let isDraggingDown = translation.y > 0
        
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
