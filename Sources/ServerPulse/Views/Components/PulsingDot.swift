import SwiftUI

struct PulsingDot: View {
    let color: Color
    let isActive: Bool
    var size: CGFloat = 10

    var body: some View {
        ZStack {
            if isActive {
                Circle()
                    .strokeBorder(color.opacity(0.28), lineWidth: 2)
                    .frame(width: size * 2.0, height: size * 2.0)
            }
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.5), radius: isActive ? 4 : 0)
        }
        .frame(width: size * 2.5, height: size * 2.5)
    }
}
