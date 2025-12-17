import Cocoa

/// Clean single-definition StatusItemController + MarqueeView
final class StatusItemController: NSObject {
    private var statusItem: NSStatusItem!
    private var marqueeView: MarqueeView?
    private var maxWidthPoints: CGFloat = 200

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.action = #selector(buttonClicked(_:))
            button.target = self
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Quit", action: #selector(quit(_:)), keyEquivalent: "q")
        statusItem.menu = menu

        setText("曲名-------------------------/------------------アーティスト", maxWidth: nil)
    }

    func setText(_ text: String, maxWidth: CGFloat?) {
        if let mw = maxWidth { maxWidthPoints = mw }
        guard let button = statusItem.button else { return }

        statusItem.length = maxWidthPoints

        if marqueeView == nil {
            marqueeView = MarqueeView(frame: NSRect(x: 0, y: 0, width: maxWidthPoints, height: button.bounds.height))
            marqueeView?.autoresizingMask = [.height]
            button.addSubview(marqueeView!)
        } else {
            marqueeView?.frame = NSRect(x: 0, y: 0, width: maxWidthPoints, height: button.bounds.height)
        }

        marqueeView?.setText(text, containerWidth: maxWidthPoints, font: button.font)
    }

    @objc private func buttonClicked(_ sender: Any?) {}
    @objc private func quit(_ sender: Any?) { NSApp.terminate(nil) }
}

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

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
        addSubview(label)
        label.wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError("Not supported") }

    func setText(_ text: String, containerWidth: CGFloat, font: NSFont?) {
        self.containerWidth = containerWidth
        label.font = font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        label.stringValue = text

        let attrs: [NSAttributedString.Key: Any] = [.font: label.font as Any]
        textWidth = NSString(string: text).size(withAttributes: attrs).width

        let h = bounds.height
        label.frame = NSRect(x: 0, y: max(0,(h - label.intrinsicContentSize.height)/2), width: textWidth, height: label.intrinsicContentSize.height)
        label.layer?.removeAllAnimations()

        if textWidth <= containerWidth {
            label.frame.origin.x = 0
            return
        }

        label.frame.origin.x = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) { [weak self] in
            self?.startSmoothMarquee()
        }
    }

    private func startSmoothMarquee() {
        guard textWidth > containerWidth, let layer = label.layer else { return }
        let distance = textWidth + gap
        let duration = TimeInterval(distance / speedPointsPerSecond)

        layer.setAffineTransform(.identity)
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
        CATransaction.setAnimationDuration(duration)
        CATransaction.setCompletionBlock { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + self.endDelay) {
                layer.removeAllAnimations()
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
        layer.add(anim, forKey: "marquee")
        CATransaction.commit()
    }

    override func layout() {
        super.layout()
        let h = bounds.height
        label.frame.origin.y = max(0,(h - label.intrinsicContentSize.height)/2)
    }
}
