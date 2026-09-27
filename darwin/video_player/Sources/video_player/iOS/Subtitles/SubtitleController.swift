#if os(iOS)
//
//  SubtitleController.swift
//  video_player
//
//  Purpose: Sidecar WebVTT subtitles — download, parse, and render cues on
//  SubtitleOverlayView in sync with AVPlayer time. No playback control.
//

import AVFoundation
import UIKit

final class SubtitleController {

    // MARK: - Properties

    let overlayView = SubtitleOverlayView()
    private weak var player: AVPlayer?

    /// Supplies the current video rect and container bounds so cues are
    /// positioned over the rendered video, not the letterbox bars.
    var layoutProvider: (() -> (videoRect: CGRect, bounds: CGRect))?

    private(set) var isEnabled = true
    private(set) var currentTrack: SubtitleTrack?
    private var cues: [WebVTTCue] = []
    private var downloadTask: URLSessionDataTask?
    private var timeObserver: Any?

    // MARK: - Initialization

    init(player: AVPlayer) {
        self.player = player
    }

    // MARK: - Public API

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if enabled, let player {
            update(at: CMTimeGetSeconds(player.currentTime()))
        } else {
            overlayView.setText(nil)
        }
    }

    func setFontSizePercent(_ percent: Int) {
        overlayView.setFontSizePercent(percent)
    }

    /// Loads a sidecar track; `nil` clears the current one.
    func load(_ track: SubtitleTrack?) {
        currentTrack = track
        downloadTask?.cancel()
        downloadTask = nil
        cues = []
        overlayView.setText(nil)

        guard let track, let url = URL(string: track.url) else {
            stopTimeObserver()
            return
        }

        downloadTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self, let data, error == nil,
                  let content = String(data: data, encoding: .utf8) else {
                return
            }
            let parsedCues = WebVTTParser.parse(vttContent: content)
            DispatchQueue.main.async {
                self.cues = parsedCues
                self.startTimeObserver()
                if let player = self.player {
                    self.update(at: CMTimeGetSeconds(player.currentTime()))
                }
            }
        }
        downloadTask?.resume()
    }

    func layout() {
        guard let layout = layoutProvider?() else { return }
        overlayView.updatePosition(videoRect: layout.videoRect, containerBounds: layout.bounds)
    }

    // MARK: - Cue Rendering

    private func update(at time: TimeInterval) {
        guard time.isFinite, isEnabled, !cues.isEmpty else {
            overlayView.setText(nil)
            return
        }
        layout()
        overlayView.setText(WebVTTParser.findCue(in: cues, at: time)?.text)
    }

    // The shared observer manager ticks every 0.5s, which is too coarse for cue
    // boundaries. Drive subtitles from their own 0.2s observer instead.
    private func startTimeObserver() {
        guard timeObserver == nil, let player else { return }
        let interval = CMTime(seconds: 0.2, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.update(at: CMTimeGetSeconds(time))
        }
    }

    private func stopTimeObserver() {
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }

    deinit {
        downloadTask?.cancel()
        stopTimeObserver()
    }
}

#endif
