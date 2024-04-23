//
//  CollectionViewController.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 21/04/22.
//
import UIKit
import SnapKit
import SDWebImage

protocol ChannelTappedDelegate {
    func onChannelTapped(channelIndex: Int, tvCategoryIndex: Int)
    
    func onTvCategoryTapped(tvCategoryIndex: Int)
}

class CollectionViewController: UIViewController {
    
    var tvCategoryIndex: Int = 0
    var delegate : ChannelTappedDelegate?
    
    var channels = [Channel]()
    var tv = [TvCategories]()
    
    let deviceIdiom = UIScreen.main.traitCollection.userInterfaceIdiom
    
    public enum UIUserInterfaceIdiom : Int {
        case unspecified
        @available(iOS 3.2, *)
        case phone // iPhone and iPod touch style UI
        @available(iOS 3.2, *)
        case pad // iPad style UI
        @available(iOS 9.0, *)
        case tv // Apple TV style UI
        @available(iOS 9.0, *)
        case carPlay // CarPlay style UI
    }
    
    lazy var channelView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero,collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(channelCollectionCell.self, forCellWithReuseIdentifier: "collectionView")
        collectionView.backgroundColor = .clear
        collectionView.reloadData()
        return collectionView
    }()
    
    lazy var tvView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero,collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(tvCollectionCell.self, forCellWithReuseIdentifier: "tvView")
        collectionView.backgroundColor = .clear
        collectionView.reloadData()
        return collectionView
    }()
    
    let menuView = UIView()
    let menuHeight = 200.0
    var isPresenting = false
    
    lazy var backView : UIView =  {
        let view = UIView()
        view.backgroundColor = Colors.backgroundBottomSheet
        return view
    }()
    
    lazy var backdropView: UIView = {
        let bdView = UIView(frame: self.view.bounds)
        bdView.backgroundColor = .clear
        return bdView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        view.backgroundColor = .clear
        backView.layer.cornerRadius = 16
        view.addSubview(backdropView)
        view.addSubview(menuView)
        menuView.backgroundColor = .clear
        menuView.addSubview(backView)
        backView.addSubview(tvView)
        backView.addSubview(channelView)
        menuView.translatesAutoresizingMaskIntoConstraints = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        backdropView.addGestureRecognizer(tapGesture)
   
    }
    
    @objc func tap() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func handleTap() {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tvView.snp.makeConstraints { make in
            make.left.right.top.equalTo(backView)
            make.height.equalTo(36)
        }
        
        channelView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(backView)
            make.top.equalTo(backView).offset(40)
            make.height.equalTo(120)
        }
        
        menuView.snp.makeConstraints { make in
            make.height.equalTo(menuHeight)
            make.bottom.equalToSuperview().inset(0)
            make.right.left.equalToSuperview()
        }
        
        backView.snp.makeConstraints { make in
            make.left.right.equalTo(menuView)
            make.bottom.top.equalTo(menuView)
        }
    }
    
    func setupUI() {
        view.addSubview(tvView)
        tvView.delegate = self
        tvView.dataSource = self
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            tvView.snp.makeConstraints { make in
                make.left.right.equalTo(0)
                make.height.equalTo(36)
            }
        } else {
            tvView.snp.makeConstraints { make in
                make.left.right.equalTo(view.safeAreaLayoutGuide)
                make.height.equalTo(36)
            }
        }
        
        view.addSubview(channelView)
        channelView.delegate = self
        channelView.dataSource = self
        
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            channelView.snp.makeConstraints { make in
                make.left.right.equalTo(view.safeAreaLayoutGuide)
                make.height.equalTo(channelView.snp_height).multipliedBy(0.5)
            }
        } else {
            channelView.snp.makeConstraints { make in
                make.left.right.equalTo(view.safeAreaLayoutGuide)
                make.width.equalTo(channelView.snp_width).multipliedBy(0.3)
            }
        }
    }
}



extension CollectionViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (collectionView == self.tvView) {
            return tv.count
        } else {
            return channels.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (collectionView == self.tvView){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tvView", for: indexPath) as! tvCollectionCell
            cell.backgroundColor = .clear
            cell.model = tv[indexPath.row]
            cell.label.text = tv[indexPath.row].title ?? ""
            cell.label.textColor = indexPath.row == tvCategoryIndex ? Colors.primary : .white
            cell.label.sizeToFit()
            return cell
        } else if collectionView == self.channelView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionView", for: indexPath) as! channelCollectionCell
            cell.backgroundColor = .clear
            cell.layer.cornerRadius = 8
            cell.model = channels[indexPath.row]
            let url = URL(string: channels[indexPath.row].image ?? "")
            cell.channelImage.sd_setImage(with: url, completed: nil)
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.tvView {
            tvCategoryIndex = indexPath.row
            delegate?.onTvCategoryTapped(tvCategoryIndex: tvCategoryIndex)
            channels = tv[indexPath.row].channels
            self.tvView.reloadData()
            self.channelView.reloadData()
        } else {
            delegate?.onChannelTapped(channelIndex: indexPath.row, tvCategoryIndex: tvCategoryIndex)
            dismiss(animated: true, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if(collectionView == self.tvView){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tvView", for: indexPath) as! tvCollectionCell
            cell.backgroundColor = .clear
            cell.model = tv[indexPath.row]
            cell.label.text = tv[indexPath.row].title ?? ""
            cell.label.sizeToFit()
            let cellWidth = cell.label.frame.width + 24
            return CGSize(width: cellWidth, height: 32)
        } else if (collectionView == self.channelView){
           return CGSize(width: 104, height: 130)
        }
        return CGSize(width: 0, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)
    }
}


//MARK: Transition animation
extension CollectionViewController: UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning  {
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
            
            UIView.animate(withDuration: 1, delay: 0.5, options: [.curveEaseOut], animations: {
                self.menuView.frame.origin.y -= self.menuHeight
                self.backdropView.alpha = 1
            }, completion: { (finished) in
                transitionContext.completeTransition(true)
            })
        } else {
            UIView.animate(withDuration: 1, delay: 0.5, options: [.curveEaseOut], animations: {
                self.menuView.frame.origin.y += self.menuHeight
                self.backdropView.alpha = 0
            }, completion: { (finished) in
                transitionContext.completeTransition(true)
            })
        }
    }
}
