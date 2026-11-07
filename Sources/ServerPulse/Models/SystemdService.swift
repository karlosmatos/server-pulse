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
            case .active:   return .brand
            case .inactive: return .gray
            case .failed:   return .down
            case .unknown:  return .warn
            }
        }

        var label: String {
            rawValue.capitalized
        }
    }
}
