import AppKit

/// A summon-on-hotkey heads-up display showing the current tool, color and
/// width, with one-click switching. Appears in the top-right corner of the
/// screen under the pointer; toggled with F8.
final class ToolHUDController {
    private let settings: AppSettings
    private let hudView: ToolHUDView
    private let panel: NSPanel

    /// Called after the user picks something in the HUD, so the rest of the app
    /// (overlay border tint, status-bar checkmarks) can refresh.
    var onChange: (() -> Void)?

    init(settings: AppSettings) {
        self.settings = settings
        self.hudView = ToolHUDView(settings: settings)

        let size = ToolHUDView.size(forColorCount: settings.palette.count)
        panel = NSPanel(contentRect: CGRect(origin: .zero, size: size),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        // Sit just above the drawing overlay so it stays visible and clickable.
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary,
                                    .fullScreenAuxiliary, .ignoresCycle]
        panel.contentView = hudView

        hudView.onChange = { [weak self] in
            self?.hudView.needsDisplay = true
            self?.onChange?()
        }
    }

    var isVisible: Bool { panel.isVisible }

    func toggle() { isVisible ? hide() : show() }

    func show() {
        reposition()
        hudView.needsDisplay = true
        panel.orderFrontRegardless()
    }

    func hide() { panel.orderOut(nil) }

    func refresh() { if isVisible { hudView.needsDisplay = true } }

    /// Top-right corner of whichever screen currently has the pointer.
    private func reposition() {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) }
            ?? NSScreen.main ?? NSScreen.screens[0]
        let f = screen.frame
        let s = panel.frame.size
        let margin: CGFloat = 24
        panel.setFrameOrigin(CGPoint(x: f.maxX - s.width - margin,
                                     y: f.maxY - s.height - margin))
    }
}

/// The custom-drawn HUD surface. Lays out three rows (tools, colors, widths)
/// plus a footer hint, and hit-tests clicks against its cells.
final class ToolHUDView: NSView {
    private let settings: AppSettings
    var onChange: (() -> Void)?

    // Layout constants
    private static let pad: CGFloat = 16
    private static let rowGap: CGFloat = 14
    private static let toolCell: CGFloat = 40, toolGap: CGFloat = 6
    private static let colorCell: CGFloat = 32, colorGap: CGFloat = 4
    private static let widthCell: CGFloat = 44, widthGap: CGFloat = 6
    private static let footerH: CGFloat = 16

    private enum CellAction { case tool(Tool), color(NSColor), width(CGFloat) }
    private struct Cell { let rect: CGRect; let action: CellAction }
    private var cells: [Cell] = []

    init(settings: AppSettings) {
        self.settings = settings
        super.init(frame: CGRect(origin: .zero,
                                 size: ToolHUDView.size(forColorCount: settings.palette.count)))
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // Keep the default bottom-left origin so NSImage/SF Symbols draw upright;
    // rows are laid out top-down and converted via `flip(_:_:)`.

    static func size(forColorCount colorCount: Int) -> CGSize {
        let toolsW = 7 * toolCell + 6 * toolGap
        let colorsW = CGFloat(colorCount) * colorCell + CGFloat(max(0, colorCount - 1)) * colorGap
        let widthsW = 4 * widthCell + 3 * widthGap
        let contentW = max(toolsW, max(colorsW, widthsW))
        let w = contentW + 2 * pad
        let h = pad + toolCell + rowGap + colorCell + rowGap + widthCell + rowGap + footerH + pad
        return CGSize(width: w, height: h)
    }

    // MARK: - Layout

    /// Converts a top-measured y into the view's bottom-left coordinate space.
    private func flip(_ yTop: CGFloat, _ height: CGFloat) -> CGFloat {
        bounds.height - yTop - height
    }

    private func layoutCells() {
        cells.removeAll()
        let P = Self.pad
        let contentW = bounds.width - 2 * P
        var yTop = P

        // Tools row (centered)
        let toolsW = 7 * Self.toolCell + 6 * Self.toolGap
        var x = P + (contentW - toolsW) / 2
        for tool in Tool.allCases {
            cells.append(Cell(rect: CGRect(x: x, y: flip(yTop, Self.toolCell),
                                           width: Self.toolCell, height: Self.toolCell),
                              action: .tool(tool)))
            x += Self.toolCell + Self.toolGap
        }
        yTop += Self.toolCell + Self.rowGap

        // Colors row (centered)
        let colorsW = CGFloat(settings.palette.count) * Self.colorCell
            + CGFloat(max(0, settings.palette.count - 1)) * Self.colorGap
        x = P + (contentW - colorsW) / 2
        for color in settings.palette {
            cells.append(Cell(rect: CGRect(x: x, y: flip(yTop, Self.colorCell),
                                           width: Self.colorCell, height: Self.colorCell),
                              action: .color(color)))
            x += Self.colorCell + Self.colorGap
        }
        yTop += Self.colorCell + Self.rowGap

        // Widths row (centered)
        let widthsW = 4 * Self.widthCell + 3 * Self.widthGap
        x = P + (contentW - widthsW) / 2
        for preset in AppSettings.widthPresets {
            cells.append(Cell(rect: CGRect(x: x, y: flip(yTop, Self.widthCell),
                                           width: Self.widthCell, height: Self.widthCell),
                              action: .width(preset.value)))
            x += Self.widthCell + Self.widthGap
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        layoutCells()

        // Panel background
        let panel = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 16, yRadius: 16)
        NSColor(calibratedWhite: 0.13, alpha: 0.97).setFill()
        panel.fill()
        NSColor(calibratedWhite: 1, alpha: 0.12).setStroke()
        panel.lineWidth = 1
        panel.stroke()

        for cell in cells {
            switch cell.action {
            case .tool(let tool):   drawToolCell(cell.rect, tool)
            case .color(let color): drawColorCell(cell.rect, color)
            case .width(let value): drawWidthCell(cell.rect, value)
            }
        }

        drawFooter()
    }

    private func drawToolCell(_ rect: CGRect, _ tool: Tool) {
        let selected = tool == settings.tool
        if selected { drawSelection(rect) }
        let tint: NSColor = selected ? .white : NSColor(calibratedWhite: 1, alpha: 0.75)
        if let img = symbolImage(tool.symbolName, pointSize: 18, color: tint) {
            let s = img.size
            img.draw(at: CGPoint(x: rect.midX - s.width / 2, y: rect.midY - s.height / 2),
                     from: .zero, operation: .sourceOver, fraction: 1)
        }
    }

    private func drawColorCell(_ rect: CGRect, _ color: NSColor) {
        let selected = sameColor(color, settings.color)
        let d: CGFloat = 22
        let dot = CGRect(x: rect.midX - d / 2, y: rect.midY - d / 2, width: d, height: d)
        color.setFill()
        NSBezierPath(ovalIn: dot).fill()
        // subtle outline for light colors
        NSColor(calibratedWhite: 0, alpha: 0.2).setStroke()
        let outline = NSBezierPath(ovalIn: dot.insetBy(dx: 0.5, dy: 0.5)); outline.lineWidth = 1; outline.stroke()
        if selected {
            NSColor.white.setStroke()
            let ring = NSBezierPath(ovalIn: rect.insetBy(dx: 3, dy: 3)); ring.lineWidth = 2.5; ring.stroke()
        }
    }

    private func drawWidthCell(_ rect: CGRect, _ value: CGFloat) {
        let selected = abs(value - settings.width) < 0.001
        if selected { drawSelection(rect) }
        let d = min(rect.width - 14, 4 + value * 1.2)
        let dot = CGRect(x: rect.midX - d / 2, y: rect.midY - d / 2, width: d, height: d)
        (selected ? NSColor.white : NSColor(calibratedWhite: 1, alpha: 0.8)).setFill()
        NSBezierPath(ovalIn: dot).fill()
    }

    private func drawSelection(_ rect: CGRect) {
        let r = rect.insetBy(dx: 2, dy: 2)
        NSColor(calibratedWhite: 1, alpha: 0.16).setFill()
        NSBezierPath(roundedRect: r, xRadius: 9, yRadius: 9).fill()
        settings.color.setStroke()
        let b = NSBezierPath(roundedRect: r, xRadius: 9, yRadius: 9); b.lineWidth = 2; b.stroke()
    }

    private func drawFooter() {
        let text = "F8 to hide · click to pick"
        let style = NSMutableParagraphStyle(); style.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: NSColor(calibratedWhite: 1, alpha: 0.4),
            .paragraphStyle: style
        ]
        // Footer sits in the bottom padding band.
        let y = (Self.pad - Self.footerH) / 2
        (text as NSString).draw(in: CGRect(x: 0, y: max(4, y), width: bounds.width, height: Self.footerH),
                                withAttributes: attrs)
    }

    // MARK: - Input

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        guard let cell = cells.first(where: { $0.rect.contains(p) }) else { return }
        switch cell.action {
        case .tool(let tool):   settings.tool = tool
        case .color(let color): settings.color = color
        case .width(let value): settings.width = value
        }
        onChange?()
    }

    // MARK: - Helpers

    private func symbolImage(_ name: String, pointSize: CGFloat, color: NSColor) -> NSImage? {
        let cfg = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(cfg) else { return nil }
        let img = NSImage(size: base.size)
        img.lockFocus()
        base.draw(at: .zero, from: CGRect(origin: .zero, size: base.size),
                  operation: .sourceOver, fraction: 1)
        color.set()
        CGRect(origin: .zero, size: base.size).fill(using: .sourceAtop)
        img.unlockFocus()
        return img
    }

    private func sameColor(_ a: NSColor, _ b: NSColor) -> Bool {
        guard let x = a.usingColorSpace(.sRGB), let y = b.usingColorSpace(.sRGB) else { return a == b }
        return abs(x.redComponent - y.redComponent) < 0.01
            && abs(x.greenComponent - y.greenComponent) < 0.01
            && abs(x.blueComponent - y.blueComponent) < 0.01
    }
}
