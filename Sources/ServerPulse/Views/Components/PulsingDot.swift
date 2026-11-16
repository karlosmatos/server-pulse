import SwiftUI

/// Solid status dot with a slow expanding "ping" ring while active.
struct PulsingDot: View {
    let color: Color
    let isActive: Bool
    var size: CGFloat = 14
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// MenuBarExtra keeps its window alive after it closes; it is only key while open.
    /// Without this check the ring animates forever off-screen and burns CPU.
    @Environment(\.controlActiveState) private var activeState

    var body: some View {
        ZStack {
            if isActive && !reduceMotion && activeState == .key {
                PingRing(color: color)
            }
            Circle().fill(color)
        }
        .frame(width: size, height: size)
    }
}

/// Removed from the hierarchy when not shown, which stops its repeating animation.
private struct PingRing: View {
    let color: Color
    @State private var pinging = false

    var body: some View {
        Circle()
            .fill(color)
            .scaleEffect(pinging ? 2 : 1)
            .opacity(pinging ? 0 : 0.6)
            .animation(.easeOut(duration: 2).repeatForever(autoreverses: false), value: pinging)
            .onAppear { pinging = true }
    }
}
