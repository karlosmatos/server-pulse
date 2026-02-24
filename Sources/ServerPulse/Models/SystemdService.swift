import SwiftUI

struct SystemdService: Identifiable {
    let id: String
    let name: String
    let state: State

    enum State: String {
        case active
        case inactive
        case failed
        case unknown

        var color: Color {
            switch self {
            case .active:   return .green
            case .inactive: return .gray
            case .failed:   return .red
            case .unknown:  return .orange
            }
        }

        var label: String {
            rawValue.capitalized
        }
    }
}
