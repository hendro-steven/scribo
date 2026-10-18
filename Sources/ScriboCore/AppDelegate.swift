import AppKit
import Carbon.HIToolbox

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = AppSettings()
    private let hotKeys = HotKeyManager()
    private var overlay: OverlayController!
    private var statusBar: StatusBarController!
    private var hud: ToolHUDController!

    public override init() { super.init() }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        Preferences.shared.load(into: settings)
        overlay = OverlayController(settings: settings)
        hud = ToolHUDController(settings: settings)
        statusBar = StatusBarController(settings: settings, overlay: overlay)

        // When the HUD changes a setting, refresh the overlay tint + menu state.
        hud.onChange = { [weak self] in
            self?.overlay.refresh()
            self?.statusBar.refresh()
        }
        statusBar.onToggleHUD = { [weak self] in self?.hud.toggle() }

        registerHotKeys()
    }

    private func registerHotKeys() {
        // F9 — toggle draw mode
        hotKeys.register(keyCode: kVK_F9) { [weak self] in
            self?.overlay.toggleActive()
            self?.statusBar.refresh()
        }
        // F10 — clear
        hotKeys.register(keyCode: kVK_F10) { [weak self] in self?.overlay.clearAll() }
        // F11 — undo
        hotKeys.register(keyCode: kVK_F11) { [weak self] in self?.overlay.undo() }
        // Shift+F11 — redo
        hotKeys.register(keyCode: kVK_F11, modifiers: shiftKey) { [weak self] in self?.overlay.redo() }
        // F8 — toggle the on-screen tool HUD
        hotKeys.register(keyCode: kVK_F8) { [weak self] in self?.hud.toggle() }
    }
}
