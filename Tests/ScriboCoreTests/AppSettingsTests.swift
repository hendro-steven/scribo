import Testing
import AppKit
@testable import ScriboCore

struct AppSettingsTests {
    @Test func startsWithExpectedDefaults() {
        let s = AppSettings()
        #expect(s.tool == .pen)
        #expect(s.width == 4)
        #expect(s.active == false)
        #expect(!s.palette.isEmpty)
    }

    @Test func widthPresetsAreOrderedAndFour() {
        let values = AppSettings.widthPresets.map(\.value)
        #expect(values.count == 4)
        #expect(values == values.sorted())
        #expect(!AppSettings.widthPresets.contains { $0.name.isEmpty })
    }
}
