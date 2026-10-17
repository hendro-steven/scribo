import Testing
import Foundation
import AppKit
@testable import ScriboCore

struct PreferencesTests {
    @Test func configDefaultsAreSensible() {
        let c = Preferences.Config()
        #expect(c.defaultWidth == 4)
        #expect(c.defaultColorHex.hasPrefix("#"))
        #expect(!c.paletteHex.isEmpty)
    }

    @Test func configRoundTripsThroughJSON() throws {
        let original = Preferences.Config(
            defaultColorHex: "#123456",
            defaultWidth: 7,
            paletteHex: ["#000000", "#FFFFFF"]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Preferences.Config.self, from: data)
        #expect(decoded.defaultColorHex == "#123456")
        #expect(decoded.defaultWidth == 7)
        #expect(decoded.paletteHex == ["#000000", "#FFFFFF"])
    }

    @Test func everyDefaultPaletteColorIsValidHex() {
        for hex in Preferences.Config().paletteHex {
            #expect(NSColor(hex: hex) != nil, "palette hex \(hex) should parse")
        }
    }
}
