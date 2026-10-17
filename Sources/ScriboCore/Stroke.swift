import AppKit

/// One committed (or in-progress) mark on the canvas.
struct Stroke {
    var tool: Tool
    var color: NSColor
    var width: CGFloat
    var points: [CGPoint]

    /// Builds the Cocoa path for this stroke based on its tool.
    func bezierPath() -> NSBezierPath {
        let path = NSBezierPath()
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.lineWidth = width

        guard let first = points.first else { return path }
        let last = points.last ?? first

        switch tool {
        case .pen, .highlighter, .eraser:
            path.move(to: first)
            for p in points.dropFirst() { path.line(to: p) }
            // A single click (no drag) should still leave a dot.
            if points.count == 1 { path.line(to: CGPoint(x: first.x + 0.1, y: first.y)) }

        case .line:
            path.move(to: first)
            path.line(to: last)

        case .arrow:
            path.move(to: first)
            path.line(to: last)
            appendArrowHead(to: path, from: first, to: last)

        case .rectangle:
            path.appendRect(rect(from: first, to: last))

        case .ellipse:
            path.appendOval(in: rect(from: first, to: last))
        }
        return path
    }

    private func rect(from a: CGPoint, to b: CGPoint) -> CGRect {
        CGRect(x: min(a.x, b.x), y: min(a.y, b.y),
               width: abs(a.x - b.x), height: abs(a.y - b.y))
    }

    private func appendArrowHead(to path: NSBezierPath, from: CGPoint, to: CGPoint) {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let headLength = max(12, width * 3)
        let spread = CGFloat.pi / 7
        let left = CGPoint(x: to.x - headLength * cos(angle - spread),
                           y: to.y - headLength * sin(angle - spread))
        let right = CGPoint(x: to.x - headLength * cos(angle + spread),
                            y: to.y - headLength * sin(angle + spread))
        path.move(to: to); path.line(to: left)
        path.move(to: to); path.line(to: right)
    }
}
