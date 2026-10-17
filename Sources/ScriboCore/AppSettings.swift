import AppKit

/// Shared, mutable drawing state. A single instance is handed to every
/// canvas and to the status-bar menu, so a change made in one place is
/// reflected everywhere immediately.
final class AppSettings {
    var tool: Tool = .pen
    var color: NSColor = .systemRed
    var width: CGFloat = 4
    /// Whether draw mode is engaged (overlays capture the mouse) or the
    /// overlays are click-through.
    var active: Bool = false

    /// Quick-pick palette shown in the Colors menu. Overridable via config.
    var palette: [NSColor] = [
        .systemRed, .systemOrange, .systemYellow, .systemGreen,
        .systemBlue, .systemPurple, .systemPink, .white, .black
    ]

    /// Named widths for the Pen Width menu.
    static let widthPresets: [(name: String, value: CGFloat)] = [
        ("Fine", 2), ("Medium", 4), ("Bold", 8), ("Marker", 16)
    ]
}
