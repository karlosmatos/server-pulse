import Observation
import Sparkle

/// Sparkle "gentle reminders": a scheduled check that finds a new release only flags it
/// in the popover footer instead of popping Sparkle's alert over whatever the user is doing.
/// Clicking "Check for Updates…" then brings up the pending update.
@Observable
@MainActor
final class UpdateReminder: NSObject, SPUStandardUserDriverDelegate {
    private(set) var availableVersion: String?

    nonisolated var supportsGentleScheduledUpdateReminders: Bool { true }

    nonisolated func standardUserDriverShouldHandleShowingScheduledUpdate(
        _ update: SUAppcastItem,
        andInImmediateFocus immediateFocus: Bool
    ) -> Bool {
        false
    }

    nonisolated func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        guard !state.userInitiated else { return }
        let version = update.displayVersionString
        MainActor.assumeIsolated { availableVersion = version }
    }

    nonisolated func standardUserDriverWillFinishUpdateSession() {
        MainActor.assumeIsolated { availableVersion = nil }
    }
}
