import SwiftUI

struct MenuBarLabel: View {
    let status: ServerStatus

    var body: some View {
        Image(systemName: "circle.fill")
            .foregroundStyle(status.color)
            .symbolEffect(.pulse, options: .repeating, isActive: status == .unknown)
    }
}
