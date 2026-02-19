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
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Spacer()
                trailing
            }
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.quaternary.opacity(0.5))
                .overlay(alignment: .top) {
                    tint.opacity(0.6)
                        .frame(height: 2)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 10,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 10
                            )
                        )
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
