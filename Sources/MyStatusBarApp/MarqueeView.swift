import Cocoa

/// MarqueeView: encapsulates smooth marquee behavior.
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
    private var endDelay: TimeInterval = 1.0
    private let gap: CGFloat = 30
    private let animKey = "marquee.translation"

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
        addSubview(label)
        label.wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError("Not supported") }

    /// Update the displayed text and start/stop marquee as needed.
    func setText(_ text: String, containerWidth: CGFloat, font: NSFont?) {
        self.containerWidth = containerWidth
        label.font = font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        label.stringValue = text

        // measure width
        let attrs: [NSAttributedString.Key: Any] = [.font: label.font as Any]
        textWidth = NSString(string: text).size(withAttributes: attrs).width

        // layout label
        let h = bounds.height
        let labelH = label.intrinsicContentSize.height
        label.frame = NSRect(x: 0, y: max(0, (h - labelH) / 2), width: textWidth, height: labelH)

        // remove any existing animations
        label.layer?.removeAllAnimations()

        if textWidth <= containerWidth {
            // fits: left align
            label.frame.origin.x = 0
            return
        }

        // otherwise schedule marquee after startDelay
        label.frame.origin.x = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) { [weak self] in
            self?.startSmoothMarquee()
        }
    }

    private func startSmoothMarquee() {
        guard textWidth > containerWidth, let layer = label.layer else { return }

        // distance needed so the label's right edge aligns with the container's right edge
        let distance = textWidth - containerWidth
        guard distance > 0 else { return }

        let duration = TimeInterval(distance / speedPointsPerSecond)

        // reset any transform
        layer.setAffineTransform(.identity)

        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
        CATransaction.setAnimationDuration(duration)
        CATransaction.setCompletionBlock { [weak self] in
            guard let self = self else { return }
            // When animation completes, keep the end visible for `endDelay`, then
            // reset to the start and (after startDelay) begin again.
            DispatchQueue.main.asyncAfter(deadline: .now() + self.endDelay) {
                layer.removeAllAnimations()
                // snap back to the start
                layer.setAffineTransform(.identity)
                DispatchQueue.main.asyncAfter(deadline: .now() + self.startDelay) {
                    self.startSmoothMarquee()
                }
            }
        }

        let anim = CABasicAnimation(keyPath: "transform.translation.x")
        anim.fromValue = 0
        anim.toValue = -distance
        anim.duration = duration
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        layer.add(anim, forKey: animKey)

        CATransaction.commit()
    }

    override func layout() {
        super.layout()
        let h = bounds.height
        label.frame.origin.y = max(0, (h - label.intrinsicContentSize.height) / 2)
    }
}
