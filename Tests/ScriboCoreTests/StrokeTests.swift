import Testing
import AppKit
@testable import ScriboCore

struct StrokeTests {
    private func stroke(_ tool: Tool, _ points: [CGPoint]) -> Stroke {
        Stroke(tool: tool, color: .red, width: 4, points: points)
    }

    @Test func lineHasTwoPathElements() {
        let path = stroke(.line, [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 20)]).bezierPath()
        #expect(path.elementCount == 2)   // moveTo + lineTo
    }

    @Test func penWithMultiplePointsTracksEachPoint() {
        let pts = [CGPoint(x: 0, y: 0), CGPoint(x: 5, y: 5), CGPoint(x: 10, y: 0)]
        let path = stroke(.pen, pts).bezierPath()
        #expect(path.elementCount == 3)   // moveTo + 2 lineTo
    }

    @Test func singleClickStillLeavesAMark() {
        let path = stroke(.pen, [CGPoint(x: 3, y: 3)]).bezierPath()
        #expect(path.elementCount >= 2)   // a dot, not an empty path
    }

    @Test func rectangleBoundsMatchTheDraggedRect() {
        let path = stroke(.rectangle, [CGPoint(x: 10, y: 10), CGPoint(x: 40, y: 50)]).bezierPath()
        let b = path.bounds
        #expect(abs(b.origin.x - 10) < 0.001)
        #expect(abs(b.origin.y - 10) < 0.001)
        #expect(abs(b.width - 30) < 0.001)
        #expect(abs(b.height - 40) < 0.001)
    }

    @Test func rectangleNormalisesReversedDragDirection() {
        // Dragging bottom-right to top-left should yield the same rect.
        let path = stroke(.rectangle, [CGPoint(x: 40, y: 50), CGPoint(x: 10, y: 10)]).bezierPath()
        let b = path.bounds
        #expect(abs(b.origin.x - 10) < 0.001)
        #expect(abs(b.origin.y - 10) < 0.001)
        #expect(abs(b.width - 30) < 0.001)
        #expect(abs(b.height - 40) < 0.001)
    }

    @Test func emptyPointsProducesEmptyPath() {
        let path = stroke(.pen, []).bezierPath()
        #expect(path.elementCount == 0)
    }

    @Test func pathUsesStrokeWidth() {
        let path = stroke(.line, [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 1)]).bezierPath()
        #expect(path.lineWidth == 4)
    }
}
