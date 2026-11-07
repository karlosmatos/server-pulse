import SwiftUI

struct GaugeBar: View {
    let value: Double // 0.0–1.0
    @State private var animatedValue: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.trackFill)
                Capsule()
                    .fill(Color.usage(value))
                    .frame(width: max(0, geo.size.width * min(animatedValue, 1)))
            }
        }
        .frame(height: 5)
        .clipShape(Capsule())
        .onChange(of: value, initial: true) { _, v in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                animatedValue = v
            }
        }
    }
}
