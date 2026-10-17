import AppKit

/// The drawing instruments Scribo offers, mirroring gromit-mpx's tool set.
enum Tool: String, CaseIterable {
    case pen
    case highlighter
    case line
    case arrow
    case rectangle
    case ellipse
    case eraser

    var displayName: String {
        switch self {
        case .pen:         return "Pen"
        case .highlighter: return "Highlighter"
        case .line:        return "Line"
        case .arrow:       return "Arrow"
        case .rectangle:   return "Rectangle"
        case .ellipse:     return "Ellipse"
        case .eraser:      return "Eraser"
        }
    }

    /// SF Symbol used in the status-bar menu.
    var symbolName: String {
        switch self {
        case .pen:         return "pencil"
        case .highlighter: return "highlighter"
        case .line:        return "line.diagonal"
        case .arrow:       return "arrow.up.right"
        case .rectangle:   return "rectangle"
        case .ellipse:     return "circle"
        case .eraser:      return "eraser"
        }
    }

    /// Freehand tools sample every mouse-drag point; shape tools only need
    /// the first and last point.
    var isFreehand: Bool {
        self == .pen || self == .highlighter || self == .eraser
    }
}
