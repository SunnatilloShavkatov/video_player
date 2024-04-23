//
//  EpisodeCollectionUI.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 21/04/22.
//

import UIKit
import TinyConstraints

protocol EpisodeDelegate{
    func onEpisodeCellTapped(seasonIndex : Int, episodeIndex : Int)
}

class EpisodeCollectionUI: UIViewController, BottomSheetCellDelegateSeason, UICollectionViewDelegate{
    
    var seasons = [Season]()
    var closeText : String = ""
    var seasonText : String = ""
    let videoPlayer = VideoPlayerViewController()
    var seasonIndex: Int = 0
    var episodeIndex: Int = 0
    var delegate : EpisodeDelegate?
    
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
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero,collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(EpisodeCollectionCell.self, forCellWithReuseIdentifier: "cell")
        return collectionView
    }()
    
    let menuView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.moreColor
        return view
    }()
    
    var menuHeight = UIScreen.main.bounds.height * 0.36
    var isPresenting = false
    
    var topView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    var verticalStack: UIStackView = {
        let st = UIStackView()
        st.alignment = .leading
        st.axis = .vertical
        st.distribution = .fill
        st.spacing = 16
        st.isUserInteractionEnabled = true
        st.backgroundColor = .clear
        st.translatesAutoresizingMaskIntoConstraints = true
        return st
    }()
    
    lazy var seasonSelectBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .white
        button.setTitle("\(seasonIndex + 1) \(seasonText)", for: .normal)
        button.setImage(Svg.down!, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.semanticContentAttribute = .forceRightToLeft
        button.backgroundColor = .red
        button.clipsToBounds = true
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .center
        button.layer.cornerRadius = 4
        button.addTarget(self, action: #selector(seasonSelectionTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var cancelBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(Svg.exit!, for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = .white
        button.addTarget(self, action: #selector(tap), for: .touchUpInside)
        return button
    }()
    
    lazy var backdropView: UIView = {
        let bdView = UIView(frame: self.view.bounds)
        bdView.backgroundColor = .clear
        return bdView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            if(UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight){
                menuHeight = UIScreen.main.bounds.width * 0.4
            } else {
                menuHeight = UIScreen.main.bounds.height * 0.35
            }
        } else {
            if(UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight){
                menuHeight = UIScreen.main.bounds.width * 0.4
            } else {
                menuHeight = UIScreen.main.bounds.height * 0.4
            }
        }
        seasonSelectBtn.setTitle("\(seasonIndex + 1) \(seasonText)", for: .normal)
        
        setupUI()
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            print("running on iPhone")
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            print("running on iPad")
        }
        
        view.backgroundColor = .clear
        view.addSubview(backdropView)
        view.addSubview(menuView)
        menuView.addSubview(verticalStack)
        verticalStack.addArrangedSubviews(topView , backView)
        backView.addSubview(collectionView)
        topView.addSubview(headerView)
        headerView.addSubview(seasonSelectBtn)
        seasonSelectBtn.backgroundColor = Colors.seasonColor
        headerView.addSubview(cancelBtn)
        menuView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        backdropView.addGestureRecognizer(tapGesture)
        
        seasonSelectBtn.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.width.equalTo(124)
            make.left.equalTo(headerView)
        }
        
        cancelBtn.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.width.equalTo(40)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        headerView.snp.makeConstraints { make in
            make.height.equalTo(topView)
            make.top.equalTo(topView).offset(0)
            make.left.equalTo(topView).offset(16)
            make.right.equalTo(topView).offset(-8)
        }
        
        topView.snp.makeConstraints { make in
            make.right.left.equalTo(backView)
            make.height.equalTo(40)
        }
        
        verticalStack.snp.makeConstraints { make in
            make.left.equalTo(menuView).offset(0)
            make.right.equalTo(menuView)
            make.bottom.equalTo(menuView).offset(0)
            make.top.equalTo(menuView).offset(18)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        collectionView.reloadData()
    }
    
    @objc func tap() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func seasonSelectionTapped() {
        let seasonVC = SeasonSelectionController()
        seasonVC.modalPresentationStyle = .overCurrentContext
        seasonVC.items = seasons
        seasonVC.closeText = closeText
        seasonVC.cellDelegate = self
        seasonVC.bottomSheetType = .season
        seasonVC.selectedIndex = seasonIndex
        seasonVC.episodeIndex = episodeIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.present(seasonVC, animated: false, completion:nil)
        }
    }
    
    func updateSeasonNumber(index:Int) {
        videoPlayer.selectedSeason = index
    }
    
    @objc func handleTap() {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.snp.makeConstraints { make in
            make.width.equalTo(backView)
            make.height.equalTo(backView)
            make.bottom.equalTo(backView)
        }
        
        backView.leading(to: view.safeAreaLayoutGuide, offset: 0)
        backView.trailing(to: view.safeAreaLayoutGuide, offset: 0)
        backView.bottom(to: view.safeAreaLayoutGuide, offset: 0)
        
        menuView.snp.makeConstraints { make in
            make.height.equalTo(menuHeight)
            make.bottom.equalToSuperview()
            make.right.left.equalToSuperview()
        }
    }
    
    func setupUI() {
        view.addSubview(collectionView)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.snp.makeConstraints { make in
                make.height.equalTo(collectionView.snp_height).multipliedBy(0.5)
            }
    }
    
    func onBottomSheetCellTapped(index: Int, type: SeasonBottomSheetType) {
        videoPlayer.updateSeasonNum(index: index)
        seasonIndex = index
        seasonSelectBtn.setTitle("\(seasonIndex+1) сезон", for: .normal)
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.userInterfaceIdiom == .phone {
            if(UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight){
                menuHeight = UIScreen.main.bounds.width * 0.4
            } else {
                menuHeight = UIScreen.main.bounds.height * 0.35
            }
        } else {
            if(UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight){
                menuHeight = UIScreen.main.bounds.width * 0.4
            } else {
                menuHeight = UIScreen.main.bounds.height * 0.4
            }
        }
    }
}

extension EpisodeCollectionUI: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return seasons[seasonIndex].movies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! EpisodeCollectionCell
        cell.backgroundColor = .clear
        cell.layer.cornerRadius = 8
        if episodeIndex == indexPath.row {
            cell.titleLbl.textColor = Colors.blue
            cell.durationLbl.textColor = Colors.blue
            cell.descriptionLabel.textColor = Colors.blue
        }
        cell.episodes = seasons[seasonIndex].movies[indexPath.row]
        let url = URL(string: seasons[seasonIndex].movies[indexPath.row].image ?? "")
        cell.episodeImage.sd_setImage(with: url, completed: nil)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let safeFrame = view.safeAreaLayoutGuide.layoutFrame
        let size = CGSize(width: safeFrame.width, height: safeFrame.height)
        return setCollectionViewItemSize(size: size)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.onEpisodeCellTapped(seasonIndex: seasonIndex, episodeIndex: indexPath.row)
        dismiss(animated: true, completion: nil)
    }
    
    func setCollectionViewItemSize(size: CGSize) -> CGSize {
        if UIApplication.shared.statusBarOrientation.isPortrait {
            let width = (size.width - 3 * 16) / 2
            return CGSize(width: width, height: menuHeight - 60)
        } else {
            let width = (size.width - 2 * 12) / 3
            return CGSize(width: width, height: width)
        }
    }
}

//MARK: Transition animation
extension EpisodeCollectionUI: UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning  {
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
