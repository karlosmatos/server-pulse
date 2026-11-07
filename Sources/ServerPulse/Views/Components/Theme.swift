import SwiftUI

/// Palette shared with the marketing site (server-pulse-site.vercel.app).
extension Color {
    static let brand = Color(hex: 0x12B76A)
    static let warn = Color(hex: 0xF5A524)
    static let down = Color(hex: 0xF04438)
    static let accentBlue = Color(hex: 0x3080FF)
    static let accentCyan = Color(hex: 0x00B7D7)
    static let accentViolet = Color(hex: 0x8D54FF)

    /// Card fill: black 3.5% in light mode, white 5% in dark mode.
    static let cardFill = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor.white.withAlphaComponent(0.05)
            : NSColor.black.withAlphaComponent(0.035)
    })

    /// Gauge track and selected chip fill: black 8% / white 10–15%.
    static let trackFill = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor.white.withAlphaComponent(0.12)
            : NSColor.black.withAlphaComponent(0.08)
    })

    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    /// Fill colour for a 0–1 usage value: amber from 60%, red from 85%.
    static func usage(_ value: Double) -> Color {
        if value >= 0.85 { return .down }
        if value >= 0.60 { return .warn }
        return .brand
    }
}
