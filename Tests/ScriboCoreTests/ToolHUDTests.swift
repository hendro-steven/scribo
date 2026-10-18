import Testing
import AppKit
@testable import ScriboCore

struct ToolHUDTests {
    @Test func sizeIsPositiveForTypicalPalette() {
        let s = ToolHUDView.size(forColorCount: 9)
        #expect(s.width > 0)
        #expect(s.height > 0)
    }

    @Test func widthGrowsWithMoreColors() {
        let small = ToolHUDView.size(forColorCount: 3)
        let large = ToolHUDView.size(forColorCount: 20)
        #expect(large.width > small.width)
        // Height is independent of colour count (fixed rows).
        #expect(small.height == large.height)
    }

    @Test func widthNeverCollapsesBelowToolRow() {
        // Even with a single colour, the tool row keeps the HUD a sensible width.
        let s = ToolHUDView.size(forColorCount: 1)
        #expect(s.width >= 300)
    }
}
