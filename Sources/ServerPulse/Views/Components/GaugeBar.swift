import SwiftUI

struct GaugeBar: View {
    let value: Double // 0.0–1.0
    @State private var animatedValue: Double = 0

    private var gradient: LinearGradient {
        if value >= 0.85 {
            return LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
        }
        if value >= 0.60 {
            return LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
        }
        return LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                Capsule()
                    .fill(gradient)
                    .frame(width: max(0, geo.size.width * min(animatedValue, 1)))
            }
        }
        .frame(height: 6)
        .clipShape(Capsule())
        .onChange(of: value, initial: true) { _, v in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                animatedValue = v
            }
        }
    }
}
