import SwiftUI

struct SectionCard<Content: View, Trailing: View>: View {
    let icon: String
    let title: String
    let tint: Color
    @ViewBuilder var trailing: Trailing
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                trailing
            }
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

extension SectionCard where Trailing == EmptyView {
    init(icon: String, title: String, tint: Color, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.tint = tint
        self.trailing = { EmptyView() }()
        self.content = content()
    }
}

/// Compact list row used by the Docker, Services and Processes cards: dot · mono name · trailing value.
struct DotRow: View {
    let color: Color
    let name: String
    var value: String? = nil
    var valueColor: Color = .secondary

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(name)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.primary.opacity(0.75))
                .lineLimit(1).truncationMode(.middle)
            Spacer(minLength: 4)
            if let value {
                Text(value)
                    .font(.system(size: 11)).monospacedDigit()
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }
}
