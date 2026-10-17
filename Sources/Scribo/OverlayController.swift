import AppKit

/// Owns one overlay window + canvas per display and fans commands out to all
/// of them. Rebuilds itself when the screen layout changes.
final class OverlayController {
    private let settings: AppSettings
    private var windows: [OverlayWindow] = []
    private var canvases: [CanvasView] = []

    init(settings: AppSettings) {
        self.settings = settings
        rebuild()
        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    @objc private func screensChanged() { rebuild() }

    private func rebuild() {
        for w in windows { w.orderOut(nil) }
        windows.removeAll(); canvases.removeAll()

        for screen in NSScreen.screens {
            let canvas = CanvasView(settings: settings)
            let window = OverlayWindow(screen: screen, canvas: canvas)
            canvas.frame = window.contentLayoutRect
            canvas.autoresizingMask = [.width, .height]
            window.orderFrontRegardless()
            windows.append(window)
            canvases.append(canvas)
        }
        applyActiveState()
    }

    // MARK: - Draw mode

    func toggleActive() { setActive(!settings.active) }

    func setActive(_ active: Bool) {
        settings.active = active
        applyActiveState()
    }

    private func applyActiveState() {
        for window in windows {
            window.ignoresMouseEvents = !settings.active
            if settings.active {
                window.orderFrontRegardless()
                window.makeKey()
            }
        }
        canvases.forEach { $0.refresh() }
    }

    // MARK: - Commands

    func clearAll() { canvases.forEach { $0.clear() } }
    func undo()     { canvases.forEach { $0.undo() } }
    func redo()     { canvases.forEach { $0.redo() } }
    func refresh()  { canvases.forEach { $0.refresh() } }
}
