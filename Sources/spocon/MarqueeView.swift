import Cocoa
import CoreText

final class MarqueeView: NSView {
    private let label: NSTextField = {
        let l = NSTextField(labelWithString: "")
        l.isBezeled = false
        l.isEditable = false
        l.drawsBackground = false
        return l
    }()

    private var textWidth: CGFloat = 0
    private var speedPointsPerSecond: CGFloat = 30
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

    func setText(_ text: String, containerWidth: CGFloat, font: NSFont?) {
        startWorkItem?.cancel()
        restartWorkItem?.cancel()
        startWorkItem = nil
        restartWorkItem = nil

        label.font = font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        label.stringValue = text

        textWidth = measureTextWidth(text, font: label.font!)

        let h = bounds.height
        let labelH = label.intrinsicContentSize.height
        let epsilon: CGFloat = 1.0
        label.frame = NSRect(x: 0, y: max(0, (h - labelH) / 2), width: textWidth + epsilon, height: labelH)

        label.layer?.removeAllAnimations()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        label.layer?.setAffineTransform(.identity)
        CATransaction.commit()

        if textWidth <= containerWidth {
            label.frame.origin.x = 0
            return
        }

        let item = DispatchWorkItem { [weak self] in self?.startMarqueeIfNeeded() }
        startWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay, execute: item)
    }

    func setDelays(start: TimeInterval, end: TimeInterval) {
        self.startDelay = start
        self.endDelay = end
    }

    func stopMarquee() {
        startWorkItem?.cancel()
        restartWorkItem?.cancel()
        startWorkItem = nil
        restartWorkItem = nil
        label.layer?.removeAllAnimations()
    }

    private func startMarqueeIfNeeded() {
        // ensure layout is up-to-date before measuring
        layoutSubtreeIfNeeded()
        let visibleWidth = bounds.width
        guard let layer = label.layer else { return }

        let labelWidth = label.frame.width
        let distance = labelWidth - visibleWidth
        guard distance > 0 else { return }

        let duration = TimeInterval(distance / speedPointsPerSecond)

        layer.removeAllAnimations()

        let anim = CABasicAnimation(keyPath: "transform.translation.x")
        anim.fromValue = 0
        anim.toValue = -distance
        anim.duration = duration - 1.5
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        anim.fillMode = .both
        anim.isRemovedOnCompletion = false
        layer.add(anim, forKey: animKey)

        let reload = DispatchWorkItem { [weak self] in
            guard let self = self, let layer = self.label.layer else { return }
            layer.removeAllAnimations()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.setAffineTransform(.identity)
            CATransaction.commit()

            let restart = DispatchWorkItem { [weak self] in self?.startMarqueeIfNeeded() }
            self.restartWorkItem = restart
            DispatchQueue.main.asyncAfter(deadline: .now() + self.startDelay, execute: restart)
        }

        restartWorkItem = reload
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + self.endDelay, execute: reload)
    }

    override func layout() {
        super.layout()
        let h = bounds.height
        label.frame.origin.y = max(0, (h - label.intrinsicContentSize.height) / 2)
    }

    private func measureTextWidth(_ text: String, font: NSFont) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let attr = NSAttributedString(string: text, attributes: attrs)

        let framesetter = CTFramesetterCreateWithAttributedString(attr as CFAttributedString)

        let constraintSize = CGSize(width: CGFloat.greatestFiniteMagnitude,
                        height: CGFloat.greatestFiniteMagnitude)

        var fitRange = CFRange()
        let size = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(location: 0, length: attr.length),
            nil,
            constraintSize,
            &fitRange
        )

        return ceil(size.width)
    }
}
