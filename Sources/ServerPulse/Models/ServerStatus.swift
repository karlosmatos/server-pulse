import SwiftUI

enum ServerStatus: Equatable {
    case online
    case degraded
    case offline
    case unknown

    var color: Color {
        switch self {
        case .online:   return .green
        case .degraded: return .yellow
        case .offline:  return .red
        case .unknown:  return .gray
        }
    }

    var label: String {
        switch self {
        case .online:   return "Online"
        case .degraded: return "Degraded"
        case .offline:  return "Offline"
        case .unknown:  return "Unknown"
        }
    }
}
