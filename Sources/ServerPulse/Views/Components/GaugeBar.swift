import SwiftUI

struct GaugeBar: View {
    let value: Double // 0.0–1.0
    @State private var animatedValue: Double = 0

    private var fillColor: Color {
        if value >= 0.85 { return .red }
        if value >= 0.60 { return .orange }
        return .green
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                Capsule()
                    .fill(fillColor)
                    .frame(width: max(0, geo.size.width * min(animatedValue, 1)))
                    .shadow(color: fillColor.opacity(0.35), radius: 4, y: 0)
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
        .onChange(of: value, initial: true) { _, v in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                animatedValue = v
            }
        }
    }
}
