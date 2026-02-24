import SwiftUI

struct CountBadge: View {
    let count: Int
    let color: Color
    var body: some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text("\(count)").font(.system(size: 10, weight: .medium)).monospacedDigit().foregroundStyle(.secondary)
        }
    }
}
