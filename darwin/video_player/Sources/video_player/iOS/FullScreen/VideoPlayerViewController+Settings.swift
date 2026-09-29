#if os(iOS)
//
//  VideoPlayerViewController+Settings.swift
//
//  Settings sheet, quality / speed / subtitle bottom sheets and their selection handling,
//  split out of VideoPlayerViewController to keep that file small.
//

import UIKit

extension VideoPlayerViewController {
    // bottom sheet tapped
    func onBottomSheetCellTapped(index: Int, type: BottomSheetType) {
        switch type {
        case .quality:
            // Build quality list (same as showQualityBottomSheet)
            var qualities = [playerConfiguration.autoText]
            if !availableQualities.isEmpty {
                qualities.append(
                    contentsOf: availableQualities.map {
                        $0.displayName
                    })
            }

            guard index < qualities.count else {
                return
            }

            self.selectedQualityText = qualities[index]

            // Set quality using preferredPeakBitRate
            if selectedQualityText == playerConfiguration.autoText {
                // Auto mode - adaptive streaming
                playerView.changeQuality(url: "0")
            } else {
                // Find the variant and use its bandwidth
                if let variant = availableQualities.first(where: { $0.displayName == selectedQualityText }) {
                    playerView.changeQuality(url: "\(variant.bandwidth)")
                }
            }
            break
        case .speed:
            self.playerRate = Float(speedList[index])!
            self.selectedSpeedText = "\(self.playerRate)x"
            self.playerView.changeSpeed(rate: self.playerRate)
            break
        case .subtitle:
            let subtitles = playerView.setSubtitleCurrentItem()
            guard index < subtitles.count else { return }
            if !playerConfiguration.subtitles.isEmpty {
                if index == 0 {
                    isSubtitlesEnabled = false
                    UserDefaults.standard.set(false, forKey: kSubtitlesEnabled)
                    selectedSubtitle = playerConfiguration.subtitleOffText
                    playerView.setSubtitleButtonEnabled(false)
                    playerView.loadSubtitleTrack(nil)
                } else {
                    let track = playerConfiguration.subtitles[index - 1]
                    isSubtitlesEnabled = true
                    UserDefaults.standard.set(true, forKey: kSubtitlesEnabled)
                    UserDefaults.standard.set(track.lang, forKey: kSelectedSubtitleLang)
                    currentSubtitleTrack = track
                    selectedSubtitle = track.label
                    playerView.setSubtitleButtonEnabled(true)
                    playerView.loadSubtitleTrack(track)
                }
            } else {
                let selectedSubtitleLabel = subtitles[index]
                if playerView.getSubtitleTrackIsEmpty(selectedSubtitleLabel: selectedSubtitleLabel) {
                    selectedSubtitle = selectedSubtitleLabel
                }
            }
            break
        case .subtitleSize:
            guard index < subtitleSizeList.count else { return }
            let sizeText = subtitleSizeList[index]
            selectedSubtitleSize = sizeText
            let percent = Int(sizeText.replacingOccurrences(of: "%", with: "")) ?? 100
            UserDefaults.standard.set(percent, forKey: kSubtitleFontSize)
            playerView.setSubtitleFontSizePercent(percent)
            break
        case .audio:
            break
        }
    }

    func showSubtitleBottomSheet() {
        guard hasSubtitleSelection else { return }
        let subtitles = playerView.setSubtitleCurrentItem()
        let bottomSheetVC = BottomSheetViewController()
        bottomSheetVC.modalPresentationStyle = .overCurrentContext
        bottomSheetVC.items = subtitles
        bottomSheetVC.labelText = playerConfiguration.subtitleText
        bottomSheetVC.bottomSheetType = .subtitle
        let activeLabel = isSubtitlesEnabled ? selectedSubtitle : playerConfiguration.subtitleOffText
        bottomSheetVC.selectedIndex = subtitles.firstIndex(of: activeLabel) ?? 0
        bottomSheetVC.cellDelegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, self.view.window != nil else { return }
            self.present(bottomSheetVC, animated: false, completion: nil)
        }
    }

    func showSubtitleSizeBottomSheet() {
        guard hasSubtitleSelection else { return }
        let bottomSheetVC = BottomSheetViewController()
        bottomSheetVC.modalPresentationStyle = .overCurrentContext
        bottomSheetVC.items = subtitleSizeList
        bottomSheetVC.labelText = playerConfiguration.subtitleSizeText
        bottomSheetVC.bottomSheetType = .subtitleSize
        bottomSheetVC.selectedIndex = subtitleSizeList.firstIndex(of: selectedSubtitleSize) ?? 2
        bottomSheetVC.cellDelegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, self.view.window != nil else { return }
            self.present(bottomSheetVC, animated: false, completion: nil)
        }
    }

    func loadQualityVariants() {
        guard supportsQualitySelection else {
            availableQualities = []
            return
        }

        let videoUrl = playerConfiguration.url
        guard !videoUrl.isEmpty else {
            return
        }

        guard availableQualities.isEmpty else {
            return
        }

        // Background parsing doesn't affect video playback
        hlsParseTask = HlsParser.parseHlsMasterPlaylist(url: videoUrl) { [weak self] variants in
            guard let self = self else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                if !variants.isEmpty {
                    self.availableQualities = variants
                }
            }
        }
    }

    func showQualityBottomSheet() {
        guard supportsQualitySelection else { return }
        // Build quality list from parsed variants
        var listOfQuality = [playerConfiguration.autoText]
        if !availableQualities.isEmpty {
            listOfQuality.append(
                contentsOf: availableQualities.map {
                    $0.displayName
                })
        }

        let bottomSheetVC = BottomSheetViewController()
        bottomSheetVC.modalPresentationStyle = .overCurrentContext
        bottomSheetVC.items = listOfQuality
        bottomSheetVC.labelText = qualityLabelText
        bottomSheetVC.cellDelegate = self
        bottomSheetVC.bottomSheetType = .quality
        bottomSheetVC.selectedIndex = listOfQuality.firstIndex(of: selectedQualityText) ?? 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, self.view.window != nil else { return }
            self.present(bottomSheetVC, animated: false, completion: nil)
        }
    }

    func showSpeedBottomSheet() {
        let bottomSheetVC = BottomSheetViewController()
        bottomSheetVC.modalPresentationStyle = .custom
        bottomSheetVC.items = speedList
        bottomSheetVC.labelText = speedLabelText
        bottomSheetVC.cellDelegate = self
        bottomSheetVC.bottomSheetType = .speed
        bottomSheetVC.selectedIndex = speedList.firstIndex(of: "\(self.playerRate)") ?? 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, self.view.window != nil else { return }
            self.present(bottomSheetVC, animated: false, completion: nil)
        }
    }

    func buildSettingModels() -> [SettingModel] {
        var models: [SettingModel] = []

        if supportsQualitySelection, let qualityIcon = Svg.settings {
            models.append(
                SettingModel(
                    leftIcon: qualityIcon,
                    title: qualityLabelText,
                    configureLabel: selectedQualityText,
                    action: .quality
                )
            )
        }

        if let playSpeedIcon = Svg.playSpeed {
            models.append(
                SettingModel(
                    leftIcon: playSpeedIcon,
                    title: speedLabelText,
                    configureLabel: selectedSpeedText,
                    action: .speed
                )
            )
        }

        if hasSubtitleSelection {
            let subtitleIcon = Svg.ccIcon(enabled: isSubtitlesEnabled) ?? UIImage()
            let subDisplay = isSubtitlesEnabled ? selectedSubtitle : playerConfiguration.subtitleOffText
            models.append(
                SettingModel(
                    leftIcon: subtitleIcon,
                    title: playerConfiguration.subtitleText,
                    configureLabel: subDisplay,
                    action: .subtitle
                )
            )
            let textSizeIcon = UIImage(systemName: "textformat.size")?
                .withTintColor(.white, renderingMode: .alwaysOriginal) ?? Svg.settings ?? UIImage()
            models.append(
                SettingModel(
                    leftIcon: textSizeIcon,
                    title: playerConfiguration.subtitleSizeText,
                    configureLabel: selectedSubtitleSize,
                    action: .subtitleSize
                )
            )
        }

        return models
    }
}

extension VideoPlayerViewController: QualityDelegate, SpeedDelegate, SubtitleDelegate, SubtitleSizeDelegate {
    func speedBottomSheet() {
        showSpeedBottomSheet()
    }

    func qualityBottomSheet() {
        showQualityBottomSheet()
    }

    func subtitleBottomSheet() {
        showSubtitleBottomSheet()
    }

    func subtitleSizeBottomSheet() {
        showSubtitleSizeBottomSheet()
    }
}

#endif
