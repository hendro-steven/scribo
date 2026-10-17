import AppKit

/// The transparent drawing surface that fills one display. It accumulates
/// strokes and re-renders them on every frame; the eraser works by punching
/// holes in previously drawn pixels via destination-out compositing.
final class CanvasView: NSView {
    private let settings: AppSettings

    private var strokes: [Stroke] = []
    private var redoStack: [Stroke] = []
    private var current: Stroke?

    init(settings: AppSettings) {
        self.settings = settings
        super.init(frame: .zero)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override var isFlipped: Bool { false }
    override var isOpaque: Bool { false }
    // Pointer should only be grabbed in draw mode; the window handles that via
    // ignoresMouseEvents, but we also decline hit-testing when inactive.
    override func hitTest(_ point: NSPoint) -> NSView? {
        settings.active ? super.hitTest(point) : nil
    }

    // MARK: - Mouse input

    override func mouseDown(with event: NSEvent) {
        guard settings.active else { return }
        let p = convert(event.locationInWindow, from: nil)
        current = Stroke(tool: settings.tool,
                         color: settings.color,
                         width: effectiveWidth(for: settings.tool),
                         points: [p])
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard settings.active, var stroke = current else { return }
        let p = convert(event.locationInWindow, from: nil)
        if stroke.tool.isFreehand {
            stroke.points.append(p)
        } else {
            // Shapes keep anchor + moving endpoint only.
            stroke.points = [stroke.points.first ?? p, p]
        }
        current = stroke
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard settings.active, let stroke = current else { return }
        strokes.append(stroke)
        redoStack.removeAll()
        current = nil
        needsDisplay = true
    }

    private func effectiveWidth(for tool: Tool) -> CGFloat {
        switch tool {
        case .highlighter: return max(settings.width * 4, 18)
        case .eraser:      return max(settings.width * 4, 24)
        default:           return settings.width
        }
    }

    // MARK: - Commands (fanned out from OverlayController)

    func clear() { strokes.removeAll(); redoStack.removeAll(); current = nil; needsDisplay = true }

    func undo() {
        guard let last = strokes.popLast() else { return }
        redoStack.append(last); needsDisplay = true
    }

    func redo() {
        guard let s = redoStack.popLast() else { return }
        strokes.append(s); needsDisplay = true
    }

    func refresh() { needsDisplay = true }

    // MARK: - Rendering

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current else { return }

        for stroke in strokes { render(stroke, in: ctx) }
        if let current = current { render(current, in: ctx) }

        // Thin tinted border so it's obvious when draw mode is live.
        if settings.active {
            ctx.compositingOperation = .sourceOver
            let border = NSBezierPath(rect: bounds.insetBy(dx: 1, dy: 1))
            border.lineWidth = 2
            settings.color.withAlphaComponent(0.55).setStroke()
            border.stroke()
        }
    }

    private func render(_ stroke: Stroke, in ctx: NSGraphicsContext) {
        let path = stroke.bezierPath()
        if stroke.tool == .eraser {
            // Cut through everything already painted this pass.
            ctx.compositingOperation = .destinationOut
            NSColor.black.setStroke()
            path.stroke()
            ctx.compositingOperation = .sourceOver
            return
        }

        ctx.compositingOperation = .sourceOver
        let color = stroke.tool == .highlighter
            ? stroke.color.withAlphaComponent(0.35)
            : stroke.color
        color.setStroke()
        path.stroke()
    }
}
