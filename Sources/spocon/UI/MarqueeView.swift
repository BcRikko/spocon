import Cocoa

final class MarqueeView: NSView {
    private let label: NSTextField = {
        let textField = NSTextField(labelWithString: "")
        textField.isBezeled = false
        textField.isEditable = false
        textField.drawsBackground = false
        return textField
    }()

    private var textWidth: CGFloat = 0
    private var startWorkItem: DispatchWorkItem?
    private var restartWorkItem: DispatchWorkItem?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(_ text: String, containerWidth: CGFloat, font: NSFont?) {
        stopMarquee()

        let resolvedFont = font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        label.font = resolvedFont
        label.stringValue = text
        textWidth = measureTextWidth(text, font: resolvedFont)

        let height = bounds.height
        let labelHeight = label.intrinsicContentSize.height
        let epsilon: CGFloat = 1.0
        label.frame = NSRect(
            x: 0,
            y: max(0, (height - labelHeight) / 2),
            width: textWidth + epsilon,
            height: labelHeight
        )

        resetTransform()

        guard textWidth > containerWidth else {
            label.frame.origin.x = 0
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.startMarqueeIfNeeded(containerWidth: containerWidth)
        }
        startWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.UI.marqueeStartDelay, execute: workItem)
    }

    func stopMarquee() {
        startWorkItem?.cancel()
        restartWorkItem?.cancel()
        startWorkItem = nil
        restartWorkItem = nil
        label.layer?.removeAllAnimations()
    }

    // MARK: - Private

    private func resetTransform() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        label.layer?.setAffineTransform(.identity)
        CATransaction.commit()
    }

    private func startMarqueeIfNeeded(containerWidth: CGFloat) {
        layoutSubtreeIfNeeded()
        let visibleWidth = bounds.width
        guard let layer = label.layer else { return }

        let labelWidth = label.frame.width
        let distance = labelWidth - visibleWidth
        guard distance > 0 else { return }

        let duration = max(0.5, TimeInterval(distance / Constants.UI.marqueeSpeedPointsPerSecond))

        layer.removeAllAnimations()

        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = 0
        animation.toValue = -distance
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.fillMode = .both
        animation.isRemovedOnCompletion = false
        layer.add(animation, forKey: Constants.Animation.marqueeKey)

        let reloadWorkItem = DispatchWorkItem { [weak self] in
            self?.resetTransform()

            let restartWorkItem = DispatchWorkItem { [weak self] in
                self?.startMarqueeIfNeeded(containerWidth: containerWidth)
            }
            self?.restartWorkItem = restartWorkItem
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.UI.marqueeStartDelay, execute: restartWorkItem)
        }

        restartWorkItem = reloadWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + Constants.UI.marqueeEndDelay, execute: reloadWorkItem)
    }

    override func layout() {
        super.layout()
        let height = bounds.height
        label.frame.origin.y = max(0, (height - label.intrinsicContentSize.height) / 2)
    }

    private func measureTextWidth(_ text: String, font: NSFont) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let size = attributedString.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        ).size
        return ceil(size.width)
    }
}
