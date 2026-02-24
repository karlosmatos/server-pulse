import SwiftUI

struct PulsingDot: View {
    let color: Color
    let isActive: Bool
    var size: CGFloat = 10
    @State private var phase = false
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            if isActive {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: size * 2.2, height: size * 2.2)
                    .scaleEffect(phase ? 1.0 : 0.5)
                    .opacity(phase ? 0 : 0.8)
            }
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.5), radius: isActive ? 4 : 0)
        }
        .frame(width: size * 2.5, height: size * 2.5)
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
        .onChange(of: isActive) { _, active in
            if active { startTimer() } else { stopTimer() }
        }
    }

    private func startTimer() {
        stopTimer()
        guard isActive else { return }
        // Pulse once every 2.5s: animate out over 1.8s, reset, repeat.
        // A Timer at 2.5s fires ~24x/min instead of SwiftUI's 60fps driver.
        phase = false
        withAnimation(.easeOut(duration: 1.8)) { phase = true }
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            phase = false
            withAnimation(.easeOut(duration: 1.8)) { phase = true }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        phase = false
    }
}
