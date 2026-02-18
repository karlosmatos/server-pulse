import SwiftUI

struct PulsingDot: View {
    let color: Color
    let isActive: Bool
    var size: CGFloat = 10
    @State private var pulse = false

    var body: some View {
        ZStack {
            if isActive {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: size * 2.2, height: size * 2.2)
                    .scaleEffect(pulse ? 1.0 : 0.5)
                    .opacity(pulse ? 0 : 0.8)
            }
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.5), radius: isActive ? 4 : 0)
        }
        .frame(width: size * 2.5, height: size * 2.5)
        .onChange(of: isActive, initial: true) { _, active in
            pulse = false
            guard active else { return }
            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}
