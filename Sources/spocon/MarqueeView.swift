import Cocoa
import CoreText

/// Robust MarqueeView: simple, reliable marquee implemented from scratch.
/// Behavior:
/// - If text fits inside `containerWidth`, show left-aligned, no animation.
/// - If text overflows, wait `startDelay`, then scroll smoothly to show the tail.
/// - After reaching the end, wait `endDelay`, then snap back to start and wait `startDelay` before repeating.
final class MarqueeView: NSView {
    private let label: NSTextField = {
        let l = NSTextField(labelWithString: "")
        l.isBezeled = false
        l.isEditable = false
        l.drawsBackground = false
        return l
    }()

    private var containerWidth: CGFloat = 200
    private var textWidth: CGFloat = 0
    private var speedPointsPerSecond: CGFloat = 60
    private var startDelay: TimeInterval = 1.0
    private var endDelay: TimeInterval = 2.0
    private let animKey = "marquee.translation"

    private var startWorkItem: DispatchWorkItem?
    private var restartWorkItem: DispatchWorkItem?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
        addSubview(label)
        label.wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError("Not supported") }

    /// Set displayed text. Cancels any pending animations and restarts logic.
    func setText(_ text: String, containerWidth: CGFloat, font: NSFont?) {
        // cancel pending tasks
        startWorkItem?.cancel()
        restartWorkItem?.cancel()
        startWorkItem = nil
        restartWorkItem = nil

        self.containerWidth = containerWidth
        label.font = font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        label.stringValue = text

        // measure width accurately using NSLayoutManager (handles complex glyphs)
        textWidth = measureTextWidth(text, font: label.font!)

        // layout label
        let h = bounds.height
        let labelH = label.intrinsicContentSize.height
        label.frame = NSRect(x: 0, y: max(0, (h - labelH) / 2), width: textWidth, height: labelH)

        // ensure clean layer state
        label.layer?.removeAllAnimations()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        label.layer?.setAffineTransform(.identity)
        CATransaction.commit()

        if textWidth <= containerWidth {
            // fits: left align, nothing to animate
            label.frame.origin.x = 0
            return
        }

        // schedule marquee start after startDelay
        let item = DispatchWorkItem { [weak self] in self?.startMarqueeIfNeeded() }
        startWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay, execute: item)
    }

    /// Configure delays (optional)
    func setDelays(start: TimeInterval, end: TimeInterval) {
        self.startDelay = start
        self.endDelay = end
    }

    /// Stop any running marquee and cancel scheduled work.
    func stopMarquee() {
        startWorkItem?.cancel()
        restartWorkItem?.cancel()
        startWorkItem = nil
        restartWorkItem = nil
        label.layer?.removeAllAnimations()
    }

    private func startMarqueeIfNeeded() {
        let visibleWidth = bounds.width
        guard textWidth > visibleWidth, let layer = label.layer else { return }

        // compute distance to scroll so right edge aligns with visible bounds
        // add a 1pt epsilon to ensure final glyph isn't clipped by rounding
        let distance = textWidth - visibleWidth + 1.0
        guard distance > 0 else { return }

        let duration = TimeInterval(distance / speedPointsPerSecond)

        // clear previous animations
        layer.removeAllAnimations()

        // add linear translation animation
        let anim = CABasicAnimation(keyPath: "transform.translation.x")
        anim.fromValue = 0
        anim.toValue = -distance
        anim.duration = duration
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        layer.add(anim, forKey: animKey)

        // schedule snapping back after animation + endDelay
        let reload = DispatchWorkItem { [weak self] in
            guard let self = self, let layer = self.label.layer else { return }
            // remove animation and snap back without implicit animations
            layer.removeAllAnimations()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.setAffineTransform(.identity)
            CATransaction.commit()

            // schedule restart after startDelay
            let restart = DispatchWorkItem { [weak self] in self?.startMarqueeIfNeeded() }
            self.restartWorkItem = restart
            DispatchQueue.main.asyncAfter(deadline: .now() + self.startDelay, execute: restart)
        }

        restartWorkItem = reload
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + endDelay, execute: reload)
    }

    override func layout() {
        super.layout()
        let h = bounds.height
        label.frame.origin.y = max(0, (h - label.intrinsicContentSize.height) / 2)
    }

    // MARK: - Text measurement helper
    private func measureTextWidth(_ text: String, font: NSFont) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let attr = NSAttributedString(string: text, attributes: attrs)
        let line = CTLineCreateWithAttributedString(attr as CFAttributedString)
        let w = CTLineGetTypographicBounds(line, nil, nil, nil)
        return CGFloat(ceil(w))
    }
}
