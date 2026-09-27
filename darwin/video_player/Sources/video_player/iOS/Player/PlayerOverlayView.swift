#if os(iOS)
//
//  PlayerOverlayView.swift
//  video_player
//
//  Purpose: Full-screen player controls — view hierarchy and SnapKit layout only.
//  Actions are wired by PlayerView; state updates go through PlayerControlsCoordinator.
//

import SnapKit
import UIKit

final class PlayerOverlayView: UIView {

    // MARK: - Containers

    let topView = UIView()
    let bottomView = UIView()

    // MARK: - Top Bar

    let exitButton = IconButton(icon: Svg.exit, inset: 10)
    let pipButton = IconButton(icon: Svg.pip)
    let shareButton = IconButton(icon: Svg.share)
    let settingsButton = IconButton(icon: Svg.settings)
    private let titleLabelLandscape = TitleLabel()
    private let titleLabelPortrait = TitleLabel()

    // MARK: - Center

    let playButton = IconButton(icon: Svg.play, inset: 4)
    let skipForwardButton = IconButton(icon: Svg.forward, inset: 4)
    let skipBackwardButton = IconButton(icon: Svg.rewind, inset: 4)
    let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.color = .white
        view.layer.cornerRadius = 20
        return view
    }()

    // MARK: - Bottom Bar

    let currentTimeLabel = PlayerOverlayView.makeTimeLabel("00:00")
    let durationTimeLabel = PlayerOverlayView.makeTimeLabel("00:00")
    private let separatorLabel = PlayerOverlayView.makeTimeLabel(" / ")
    let rotateButton = IconButton(icon: Svg.rotate)
    let timeSlider: UISlider = {
        let slider = UISlider()
        slider.tintColor = Colors.white
        slider.maximumTrackTintColor = Colors.white27
        slider.setThumbImage(.circle(diameter: 20, color: Colors.white), for: .normal)
        slider.clipsToBounds = true
        return slider
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        bottomView.clipsToBounds = true
        [topView, playButton, skipForwardButton, skipBackwardButton,
         activityIndicator, bottomView, titleLabelPortrait].forEach(addSubview)
        [exitButton, titleLabelLandscape, settingsButton, shareButton, pipButton].forEach(topView.addSubview)
        [currentTimeLabel, durationTimeLabel, separatorLabel, timeSlider, rotateButton].forEach(bottomView.addSubview)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API

    func setTitle(_ title: String?) {
        titleLabelPortrait.isHidden = false
        titleLabelPortrait.text = title ?? ""
        titleLabelLandscape.text = title ?? ""
    }

    /// Landscape shows the title inside the top bar; portrait shows it below.
    func showTitleInTopBar(_ inTopBar: Bool) {
        titleLabelLandscape.isHidden = !inTopBar
        titleLabelPortrait.isHidden = inTopBar
    }

    func setPlayButtonVisible(_ visible: Bool) {
        playButton.alpha = visible ? 1.0 : 0.0
    }

    // MARK: - Layout

    /// Must be called once the view is in the hierarchy that owns `area`.
    func makeConstraints(area: UILayoutGuide) {
        makeCenterConstraints()
        makeTopBarConstraints(area: area)
        makeBottomBarConstraints(area: area)
    }

    private func makeCenterConstraints() {
        playButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        skipBackwardButton.snp.makeConstraints { make in
            make.right.equalTo(playButton.snp.left).offset(-60)
            make.top.equalTo(playButton)
        }
        skipForwardButton.snp.makeConstraints { make in
            make.left.equalTo(playButton.snp.right).offset(60)
            make.top.equalTo(playButton)
        }
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func makeTopBarConstraints(area: UILayoutGuide) {
        topView.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(area)
            make.height.equalTo(48)
        }
        exitButton.snp.makeConstraints { make in
            make.left.centerY.equalTo(topView)
        }
        settingsButton.snp.makeConstraints { make in
            make.right.centerY.equalTo(topView)
        }
        shareButton.snp.makeConstraints { make in
            make.right.equalTo(settingsButton.snp.left)
            make.centerY.equalTo(topView)
        }
        pipButton.snp.makeConstraints { make in
            make.left.equalTo(exitButton.snp.right)
            make.centerY.equalTo(topView)
        }
        titleLabelLandscape.snp.makeConstraints { make in
            make.center.equalTo(topView)
            make.left.equalTo(pipButton.snp.right).offset(8)
        }
        titleLabelPortrait.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(topView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }

    private func makeBottomBarConstraints(area: UILayoutGuide) {
        bottomView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(area)
        }
        timeSlider.snp.makeConstraints { make in
            make.bottom.equalTo(bottomView).offset(-8)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
        }
        rotateButton.snp.makeConstraints { make in
            make.right.equalTo(bottomView)
            make.bottom.equalTo(timeSlider.snp.top)
            make.top.greaterThanOrEqualTo(bottomView).offset(8)
        }
        currentTimeLabel.snp.makeConstraints { make in
            make.left.equalTo(bottomView).offset(8)
            make.centerY.equalTo(rotateButton)
        }
        separatorLabel.snp.makeConstraints { make in
            make.left.equalTo(currentTimeLabel.snp.right)
            make.centerY.equalTo(currentTimeLabel)
        }
        durationTimeLabel.snp.makeConstraints { make in
            make.left.equalTo(separatorLabel.snp.right)
            make.centerY.equalTo(separatorLabel)
        }
    }

    private static func makeTimeLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        return label
    }
}

#endif
