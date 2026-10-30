import AppKit

@MainActor
final class EdgeLauncherController {
    private let panel: NSPanel
    private let contentView: EdgeLauncherContentView
    private let onActivate: () -> Void
    private var collapseWorkItem: DispatchWorkItem?
    private var isExpanded = false

    init(onActivate: @escaping () -> Void) {
        self.onActivate = onActivate

        let contentView = EdgeLauncherContentView()
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 8, height: 48),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.contentView = contentView
        self.panel = panel

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentView = contentView

        contentView.onHoverChanged = { [weak self] isHovered in
            self?.handleHover(isHovered)
        }
        contentView.onClick = { [weak self] in
            self?.collapseWorkItem?.cancel()
            self?.onActivate()
        }
    }

    func show() {
        updateFrame(animated: false)
        panel.orderFrontRegardless()
    }

    func hide() {
        collapseWorkItem?.cancel()
        panel.orderOut(nil)
    }

    func reposition() {
        guard panel.isVisible else { return }
        updateFrame(animated: false)
    }

    private func handleHover(_ isHovered: Bool) {
        collapseWorkItem?.cancel()
        if isHovered {
            setExpanded(true)
        } else {
            let workItem = DispatchWorkItem { [weak self] in
                self?.setExpanded(false)
            }
            collapseWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24, execute: workItem)
        }
    }

    private func setExpanded(_ expanded: Bool) {
        guard isExpanded != expanded else { return }
        isExpanded = expanded
        contentView.isExpanded = expanded
        updateFrame(animated: true)
    }

    private func updateFrame(animated: Bool) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let visibleFrame = screen.visibleFrame
        let screenFrame = screen.frame
        let width: CGFloat = isExpanded ? 52 : 8
        let height: CGFloat = isExpanded ? 104 : 48
        let frame = NSRect(
            x: screenFrame.maxX - width,
            y: visibleFrame.midY - height / 2,
            width: width,
            height: height
        )

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.16
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }
    }
}

private final class EdgeLauncherContentView: NSView {
    var isExpanded = false {
        didSet { needsDisplay = true }
    }
    var onHoverChanged: ((Bool) -> Void)?
    var onClick: (() -> Void)?

    private var trackingArea: NSTrackingArea?

    override var acceptsFirstResponder: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("打开 AppDeck")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("打开 AppDeck")
    }

    override func updateTrackingAreas() {
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        self.trackingArea = trackingArea
        super.updateTrackingAreas()
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    override func mouseEntered(with event: NSEvent) {
        onHoverChanged?(true)
    }

    override func mouseExited(with event: NSEvent) {
        onHoverChanged?(false)
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }

    override func draw(_ dirtyRect: NSRect) {
        let inset: CGFloat = isExpanded ? 3 : 1
        let rect = bounds.insetBy(dx: inset, dy: inset)
        let path = NSBezierPath(
            roundedRect: rect,
            xRadius: isExpanded ? 16 : 4,
            yRadius: isExpanded ? 16 : 4
        )
        NSColor(calibratedWhite: 0.08, alpha: isExpanded ? 0.94 : 0.7).setFill()
        path.fill()

        guard isExpanded,
              let image = NSImage(
                systemSymbolName: "rectangle.on.rectangle.angled",
                accessibilityDescription: "打开 AppDeck"
              ) else { return }
        image.isTemplate = true
        NSColor.white.set()
        image.draw(
            in: NSRect(
                x: (bounds.width - 22) / 2,
                y: (bounds.height - 22) / 2,
                width: 22,
                height: 22
            ),
            from: .zero,
            operation: .sourceOver,
            fraction: 0.92
        )
    }
}
