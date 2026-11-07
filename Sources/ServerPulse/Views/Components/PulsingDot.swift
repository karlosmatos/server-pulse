import SwiftUI

/// Solid status dot with a slow expanding "ping" ring while active.
struct PulsingDot: View {
    let color: Color
    let isActive: Bool
    var size: CGFloat = 14
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pinging = false

    var body: some View {
        ZStack {
            if isActive && !reduceMotion {
                Circle()
                    .fill(color)
                    .scaleEffect(pinging ? 2 : 1)
                    .opacity(pinging ? 0 : 0.6)
                    .animation(.easeOut(duration: 2).repeatForever(autoreverses: false), value: pinging)
            }
            Circle().fill(color)
        }
        .frame(width: size, height: size)
        .onAppear { pinging = true }
    }
}
