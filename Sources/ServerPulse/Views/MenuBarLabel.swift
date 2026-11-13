import SwiftUI

struct MenuBarLabel: View {
    let status: ServerStatus
    let severity: Severity
    let attentionCount: Int

    var body: some View {
        if attentionCount > 0 {
            HStack(spacing: 2) {
                Image(nsImage: Self.coloredSymbol(severity.symbol, colors: [glyphColor, NSColor(severity.color)]))
                Text("\(attentionCount)").monospacedDigit()
            }
            .accessibilityLabel("ServerPulse, \(attentionCount) servers need attention")
        } else {
            Image(nsImage: Self.coloredSymbol(
                status == .unknown ? "circle.dashed" : "circle.fill",
                colors: [NSColor(status.color)]
            ))
            .accessibilityLabel("ServerPulse, \(status.label)")
        }
    }

    /// The "!" / "×" inside the severity symbol; it needs its own color or it blends into the shape.
    private var glyphColor: NSColor {
        severity == .warning ? .black : .white
    }

    /// Menu bar labels render as templates (monochrome); a non-template image keeps the status color.
    /// Palette colors apply per symbol layer, foreground layer first.
    private static func coloredSymbol(_ name: String, colors: [NSColor]) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            .applying(.init(paletteColors: colors))
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) ?? NSImage()
        image.isTemplate = false
        return image
    }
}
