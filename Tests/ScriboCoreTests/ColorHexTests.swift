import Testing
import AppKit
@testable import ScriboCore

struct ColorHexTests {
    private func rgba(_ c: NSColor) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        let s = c.usingColorSpace(.sRGB)!
        return (s.redComponent, s.greenComponent, s.blueComponent, s.alphaComponent)
    }

    @Test func parsesSixDigitHexWithHash() {
        let (r, g, b, a) = rgba(NSColor(hex: "#FF0000")!)
        #expect(abs(r - 1) < 0.01); #expect(g < 0.01); #expect(b < 0.01); #expect(abs(a - 1) < 0.01)
    }

    @Test func parsesHexWithoutHash() {
        let (r, g, b, _) = rgba(NSColor(hex: "00FF00")!)
        #expect(r < 0.01); #expect(abs(g - 1) < 0.01); #expect(b < 0.01)
    }

    @Test func parsesEightDigitHexAlpha() {
        let (_, _, _, a) = rgba(NSColor(hex: "#00000080")!)
        #expect(abs(a - 0.5) < 0.02)   // 0x80 / 255 ≈ 0.502
    }

    @Test func rejectsInvalidStrings() {
        #expect(NSColor(hex: "nothex") == nil)
        #expect(NSColor(hex: "#12345") == nil)    // wrong length
        #expect(NSColor(hex: "#1234567") == nil)  // wrong length
        #expect(NSColor(hex: "") == nil)
    }

    @Test func toleratesSurroundingWhitespace() {
        #expect(NSColor(hex: "  #0000FF  ") != nil)
    }
}
