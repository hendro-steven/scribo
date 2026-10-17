import AppKit

/// Loads/creates a small JSON config at
/// ~/Library/Application Support/Scribo/config.json so users can set their
/// default colour, width and palette (gromit-mpx keeps a .cfg similarly).
struct Preferences {
    struct Config: Codable {
        var defaultColorHex: String = "#FF3B30"
        var defaultWidth: Double = 4
        var paletteHex: [String] = [
            "#FF3B30", "#FF9500", "#FFCC00", "#34C759",
            "#007AFF", "#AF52DE", "#FF2D55", "#FFFFFF", "#000000"
        ]
    }

    static let shared = Preferences()

    var configURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
            .appendingPathComponent("Scribo", isDirectory: true)
        try? FileManager.default.createDirectory(at: base,
                                                 withIntermediateDirectories: true)
        return base.appendingPathComponent("config.json")
    }

    func load(into settings: AppSettings) {
        let url = configURL
        let config: Config
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(Config.self, from: data) {
            config = decoded
        } else {
            config = Config()
            save(config)
        }

        if let c = NSColor(hex: config.defaultColorHex) { settings.color = c }
        settings.width = CGFloat(config.defaultWidth)
        let palette = config.paletteHex.compactMap { NSColor(hex: $0) }
        if !palette.isEmpty { settings.palette = palette }
    }

    func save(_ config: Config) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(config) {
            try? data.write(to: configURL)
        }
    }
}

extension NSColor {
    /// Parses "#RRGGBB" / "#RRGGBBAA" (hash optional).
    convenience init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 8,
              let value = UInt64(s, radix: 16) else { return nil }
        let r, g, b, a: CGFloat
        if s.count == 6 {
            r = CGFloat((value >> 16) & 0xFF) / 255
            g = CGFloat((value >> 8) & 0xFF) / 255
            b = CGFloat(value & 0xFF) / 255
            a = 1
        } else {
            r = CGFloat((value >> 24) & 0xFF) / 255
            g = CGFloat((value >> 16) & 0xFF) / 255
            b = CGFloat((value >> 8) & 0xFF) / 255
            a = CGFloat(value & 0xFF) / 255
        }
        self.init(srgbRed: r, green: g, blue: b, alpha: a)
    }
}
