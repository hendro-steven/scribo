import AppKit

/// The menu-bar icon and its menu — Scribo's equivalent of gromit's tray icon.
final class StatusBarController: NSObject {
    private let settings: AppSettings
    private let overlay: OverlayController
    private let statusItem: NSStatusItem

    init(settings: AppSettings, overlay: OverlayController) {
        self.settings = settings
        self.overlay = overlay
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        buildMenu()
        refresh()
    }

    // MARK: - Menu construction

    private func buildMenu() {
        let menu = NSMenu()

        menu.addItem(item("Draw Mode", #selector(toggleDraw), key: "", tag: 1000))
        menu.addItem(.separator())

        // Tools
        let toolsItem = NSMenuItem(title: "Tool", action: nil, keyEquivalent: "")
        let toolsMenu = NSMenu()
        for tool in Tool.allCases {
            let mi = NSMenuItem(title: tool.displayName,
                                action: #selector(selectTool(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = tool.rawValue
            mi.image = NSImage(systemSymbolName: tool.symbolName, accessibilityDescription: nil)
            toolsMenu.addItem(mi)
        }
        toolsItem.submenu = toolsMenu
        menu.addItem(toolsItem)

        // Colors
        let colorItem = NSMenuItem(title: "Color", action: nil, keyEquivalent: "")
        let colorMenu = NSMenu()
        for color in settings.palette {
            let mi = NSMenuItem(title: colorName(color),
                                action: #selector(selectColor(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = color
            mi.image = swatch(color)
            colorMenu.addItem(mi)
        }
        colorItem.submenu = colorMenu
        menu.addItem(colorItem)

        // Width
        let widthItem = NSMenuItem(title: "Pen Width", action: nil, keyEquivalent: "")
        let widthMenu = NSMenu()
        for preset in AppSettings.widthPresets {
            let mi = NSMenuItem(title: preset.name,
                                action: #selector(selectWidth(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = preset.value
            widthMenu.addItem(mi)
        }
        widthItem.submenu = widthMenu
        menu.addItem(widthItem)

        menu.addItem(.separator())
        menu.addItem(item("Clear  (F10)", #selector(clear)))
        menu.addItem(item("Undo  (F11)", #selector(undo)))
        menu.addItem(item("Redo  (⇧F11)", #selector(redo)))
        menu.addItem(.separator())
        menu.addItem(item("Edit Config File…", #selector(editConfig)))
        menu.addItem(item("About Scribo", #selector(about)))
        menu.addItem(item("Quit Scribo", #selector(quit), key: "q"))

        statusItem.menu = menu
    }

    private func item(_ title: String, _ action: Selector,
                      key: String = "", tag: Int = 0) -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: action, keyEquivalent: key)
        mi.target = self
        mi.tag = tag
        return mi
    }

    // MARK: - Actions

    @objc private func toggleDraw() { overlay.toggleActive(); refresh() }
    @objc private func clear()      { overlay.clearAll() }
    @objc private func undo()       { overlay.undo() }
    @objc private func redo()       { overlay.redo() }

    @objc private func selectTool(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String, let t = Tool(rawValue: raw) {
            settings.tool = t; refresh()
        }
    }

    @objc private func selectColor(_ sender: NSMenuItem) {
        if let c = sender.representedObject as? NSColor { settings.color = c; overlay.refresh(); refresh() }
    }

    @objc private func selectWidth(_ sender: NSMenuItem) {
        if let w = sender.representedObject as? CGFloat { settings.width = w; refresh() }
    }

    @objc private func editConfig() {
        NSWorkspace.shared.open(Preferences.shared.configURL)
    }

    private static let repoURL = URL(string: "https://github.com/hendro-steven/scribo")!

    @objc private func about() {
        NSApp.activate(ignoringOtherApps: true)

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let versionLine = version.map { "Version \($0)\n\n" } ?? ""

        let alert = NSAlert()
        alert.messageText = "Scribo"
        alert.informativeText = """
        \(versionLine)On-screen annotation overlay for macOS.

        F9 — toggle draw mode
        F10 — clear
        F11 — undo   ·   ⇧F11 — redo

        Draw over anything, anywhere. Inspired by gromit-mpx.

        \(Self.repoURL.absoluteString)
        """
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "View on GitHub")
        if alert.runModal() == .alertSecondButtonReturn {
            NSWorkspace.shared.open(Self.repoURL)
        }
    }

    @objc private func quit() { NSApp.terminate(nil) }

    // MARK: - State reflection

    func refresh() {
        if let button = statusItem.button {
            let name = settings.active ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle"
            button.image = NSImage(systemSymbolName: name, accessibilityDescription: "Scribo")
            button.image?.isTemplate = true
        }
        guard let menu = statusItem.menu else { return }

        if let draw = menu.item(withTag: 1000) {
            draw.title = settings.active ? "Draw Mode: On  (F9)" : "Draw Mode: Off  (F9)"
            draw.state = settings.active ? .on : .off
        }
        // Checkmarks
        mark(menu.item(withTitle: "Tool")?.submenu) { ($0.representedObject as? String) == settings.tool.rawValue }
        mark(menu.item(withTitle: "Color")?.submenu) { ($0.representedObject as? NSColor) == settings.color }
        mark(menu.item(withTitle: "Pen Width")?.submenu) { ($0.representedObject as? CGFloat) == settings.width }
    }

    private func mark(_ submenu: NSMenu?, _ isOn: (NSMenuItem) -> Bool) {
        submenu?.items.forEach { $0.state = isOn($0) ? .on : .off }
    }

    // MARK: - Helpers

    private func swatch(_ color: NSColor) -> NSImage {
        let size = NSSize(width: 14, height: 14)
        let image = NSImage(size: size)
        image.lockFocus()
        color.setFill()
        NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 3, yRadius: 3).fill()
        NSColor.separatorColor.setStroke()
        NSBezierPath(roundedRect: NSRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5),
                     xRadius: 3, yRadius: 3).stroke()
        image.unlockFocus()
        return image
    }

    private func colorName(_ color: NSColor) -> String {
        let rgb = color.usingColorSpace(.sRGB) ?? color
        return String(format: "#%02X%02X%02X",
                      Int(rgb.redComponent * 255),
                      Int(rgb.greenComponent * 255),
                      Int(rgb.blueComponent * 255))
    }
}
