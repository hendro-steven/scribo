import Testing
@testable import ScriboCore

struct ToolTests {
    @Test func freehandToolsAreClassifiedCorrectly() {
        #expect(Tool.pen.isFreehand)
        #expect(Tool.highlighter.isFreehand)
        #expect(Tool.eraser.isFreehand)
        #expect(!Tool.line.isFreehand)
        #expect(!Tool.arrow.isFreehand)
        #expect(!Tool.rectangle.isFreehand)
        #expect(!Tool.ellipse.isFreehand)
    }

    @Test func everyToolHasNonEmptyDisplayAndSymbolNames() {
        for tool in Tool.allCases {
            #expect(!tool.displayName.isEmpty)
            #expect(!tool.symbolName.isEmpty)
        }
    }

    @Test func allCasesCoversSevenTools() {
        #expect(Tool.allCases.count == 7)
    }

    @Test func rawValueRoundTrips() {
        for tool in Tool.allCases {
            #expect(Tool(rawValue: tool.rawValue) == tool)
        }
    }
}
