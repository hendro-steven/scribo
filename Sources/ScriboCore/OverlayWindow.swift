import AppKit

/// A borderless, non-activating panel that floats above all other windows on
/// one display. Non-activating means clicking to draw does NOT steal focus
/// from the app underneath — exactly the behaviour gromit-mpx has.
final class OverlayWindow: NSPanel {
    init(screen: NSScreen, canvas: CanvasView) {
        super.init(contentRect: screen.frame,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)

        isFloatingPanel = true
        level = .screenSaver            // above Dock and menu bar
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        ignoresMouseEvents = true       // click-through until draw mode is on
        collectionBehavior = [.canJoinAllSpaces, .stationary,
                              .fullScreenAuxiliary, .ignoresCycle]

        contentView = canvas
        setFrame(screen.frame, display: true)
    }

    // Borderless panels refuse key status by default; allow it so the overlay
    // can receive events when draw mode is active.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
