import Foundation

/// One hardening rule evaluated against a server's security audit output.
struct SecurityCheck: Identifiable, Equatable {
    enum Status: Equatable {
        case pass
        case fail(Severity)
        /// The audit could not read what it needs (usually because it is not running as root).
        case unknown
    }

    let id: String
    let title: String
    let status: Status
    /// Short value shown on the right of the row, e.g. "4 pending".
    let detail: String
    /// Plain-language guidance.
    var advice: String? = nil
    /// Shell command that fixes the problem; shown monospaced with a copy button.
    var command: String? = nil

    /// Sort key: most severe failures first, then unknowns, then passes.
    var rank: Int {
        switch status {
        case .fail(let severity): return 10 + severity.rawValue
        case .unknown:            return 1
        case .pass:               return 0
        }
    }
}
