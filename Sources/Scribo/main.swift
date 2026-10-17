import AppKit

// Scribo — on-screen annotation overlay for macOS (Apple Silicon).
// A spiritual port of gromit-mpx to native AppKit.

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// .accessory => no Dock icon, lives in the menu bar only (like gromit's tray icon).
app.setActivationPolicy(.accessory)
app.run()
