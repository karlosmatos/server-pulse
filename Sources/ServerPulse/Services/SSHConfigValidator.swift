import Foundation

enum SSHConfigError: Error, LocalizedError, Equatable {
    case invalidHost
    case invalidUser

    var errorDescription: String? {
        switch self {
        case .invalidHost:
            return "SSH host contains unsupported characters or starts with an option marker."
        case .invalidUser:
            return "SSH user contains unsupported characters or starts with an option marker."
        }
    }
}

enum SSHConfigValidator {
    static func destination(for config: ServerConfig) throws -> String {
        let user = config.sshUser.trimmingCharacters(in: .whitespacesAndNewlines)
        let host = config.sshHost.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidUser(user) else { throw SSHConfigError.invalidUser }
        guard isValidHost(host) else { throw SSHConfigError.invalidHost }
        return "\(user)@\(host)"
    }

    static func isValidUser(_ user: String) -> Bool {
        guard !user.isEmpty, user.count <= 64, !user.hasPrefix("-") else { return false }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
        return user.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    static func isValidHost(_ host: String) -> Bool {
        guard !host.isEmpty, host.count <= 253, !host.hasPrefix("-") else { return false }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-_:%"))
        return host.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}
