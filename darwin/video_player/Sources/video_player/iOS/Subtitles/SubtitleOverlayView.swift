#if os(iOS)
//
//  SubtitleOverlayView.swift
//  video_player
//

import UIKit
import SnapKit

/// Label that paints a background box behind each rendered line, sized to that
/// line's text instead of to the whole label. Matches the way YouTube and the web
/// player draw cues: ragged right edge, no box around empty space.
final class SubtitleCueLabel: UILabel {

    var cueBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.78) {
        didSet { setNeedsDisplay() }
    }

    /// Horizontal padding around each line's glyphs. Vertical extent always comes
    /// from the line fragment, so boxes tile without overlapping.
    var cueHorizontalPadding: CGFloat = 8.0

    override var text: String? {
        didSet { setNeedsDisplay() }
    }

    override var font: UIFont! {
        didSet { setNeedsDisplay() }
    }

    override func drawText(in rect: CGRect) {
        drawLineBackgrounds(in: rect)
        super.drawText(in: rect)
    }

    private func drawLineBackgrounds(in rect: CGRect) {
        guard let text = text, !text.isEmpty, let font = font else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        paragraphStyle.lineBreakMode = .byWordWrapping

        let storage = NSTextStorage(
            string: text,
            attributes: [.font: font, .paragraphStyle: paragraphStyle]
        )
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer(
            size: CGSize(width: rect.width, height: .greatestFiniteMagnitude)
        )
        container.lineFragmentPadding = 0
        container.lineBreakMode = .byWordWrapping
        container.maximumNumberOfLines = numberOfLines
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)
        layoutManager.ensureLayout(for: container)

        let glyphRange = layoutManager.glyphRange(for: container)
        guard glyphRange.length > 0 else { return }

        // UILabel centres its text block vertically inside the drawing rect.
        let usedHeight = layoutManager.usedRect(for: container).height
        let verticalOffset = rect.minY + max(0, (rect.height - usedHeight) / 2.0)

        cueBackgroundColor.setFill()
        // Horizontal extent comes from the glyphs (usedRect), vertical extent from
        // the line fragment (lineRect). Fragments tile edge to edge, so adjacent
        // boxes touch instead of overlapping - overlapping translucent fills would
        // darken the seam between lines.
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { lineRect, usedRect, _, _, _ in
            guard usedRect.width > 0 else { return }
            let box = CGRect(
                x: rect.minX + usedRect.minX - self.cueHorizontalPadding,
                y: verticalOffset + lineRect.minY,
                width: usedRect.width + self.cueHorizontalPadding * 2.0,
                height: lineRect.height
            )
            UIBezierPath(rect: box.integral).fill()
        }
    }
}

public class SubtitleOverlayView: UIView {

    private let label: SubtitleCueLabel = {
        let label = SubtitleCueLabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.isHidden = true
        return label
    }()

    /// Distance between the bottom of the cue and the bottom edge of the video.
    static let bottomMargin: CGFloat = 8.0

    private var fontSizePercent: Int = 100

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        isUserInteractionEnabled = false
        backgroundColor = .clear

        addSubview(label)

        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-48)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }
    }

    public func setFontSizePercent(_ percent: Int) {
        fontSizePercent = percent
        let baseSize: CGFloat = 18.0
        let scaledSize = max(11.0, baseSize * (CGFloat(percent) / 100.0))
        label.font = UIFont.systemFont(ofSize: scaledSize, weight: .medium)
    }

    public func setText(_ text: String?) {
        guard let text = text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            guard label.text != nil else { return }
            label.isHidden = true
            label.text = nil
            return
        }

        // Called every 0.2s; reassigning the same cue would redraw the line boxes.
        guard text != label.text else { return }
        label.text = text
        label.isHidden = false
    }

    public func updatePosition(videoRect: CGRect, containerBounds: CGRect) {
        let offset: CGFloat
        if videoRect.width > 0 && videoRect.height > 0 {
            // Sit 8pt above the bottom edge of the actual video frame.
            offset = containerBounds.height - videoRect.maxY + SubtitleOverlayView.bottomMargin
        } else {
            offset = 48.0
        }
        label.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(-max(SubtitleOverlayView.bottomMargin, offset))
        }
    }

    public func setBottomOffset(_ offset: CGFloat) {
        label.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(-offset)
        }
    }
}
#endif
