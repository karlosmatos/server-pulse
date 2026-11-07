import SwiftUI

enum ServerStatus: Equatable {
    case online
    case degraded
    case offline
    case unknown

    var color: Color {
        switch self {
        case .online:   return .brand
        case .degraded: return .warn
        case .offline:  return .down
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
