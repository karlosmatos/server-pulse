import SwiftUI

struct MenuBarLabel: View {
    let status: ServerStatus
    let severity: Severity
    let attentionCount: Int

    var body: some View {
        if attentionCount > 0 {
            HStack(spacing: 2) {
                Image(nsImage: Self.coloredSymbol(severity.symbol, color: NSColor(severity.color)))
                Text("\(attentionCount)").monospacedDigit()
            }
            .accessibilityLabel("ServerPulse, \(attentionCount) servers need attention")
        } else {
            Image(nsImage: Self.coloredSymbol(
                status == .unknown ? "circle.dashed" : "circle.fill",
                color: NSColor(status.color)
            ))
            .accessibilityLabel("ServerPulse, \(status.label)")
        }
    }

    /// Menu bar labels render as templates (monochrome); a non-template image keeps the status color.
    private static func coloredSymbol(_ name: String, color: NSColor) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            .applying(.init(paletteColors: [color]))
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) ?? NSImage()
        image.isTemplate = false
        return image
    }
}
