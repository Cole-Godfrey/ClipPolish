import ClipPolishCore

enum StatusMessage: Equatable, Sendable {
    case noPlainText
    case alreadyClean
    case cleaned(totalCharactersRemoved: Int)
    case clipboardReadFailed
    case clipboardWriteFailed
    case automationPermissionRequired
    case automationPermissionRequestDenied
    case automationPermissionGranted

    var displayText: String {
        switch self {
        case .noPlainText:
            return "No plain text to clean"
        case .alreadyClean:
            return "Already clean"
        case let .cleaned(totalCharactersRemoved):
            return "Cleaned clipboard text (\(totalCharactersRemoved) removed)"
        case .clipboardReadFailed:
            return "Could not read clipboard text"
        case .clipboardWriteFailed:
            return "Could not update clipboard text"
        case .automationPermissionRequired:
            return "Enable Accessibility permission to use hotkey clean-and-paste"
        case .automationPermissionRequestDenied:
            return "Accessibility permission is still required for hotkey clean-and-paste"
        case .automationPermissionGranted:
            return "Accessibility permission granted for hotkey clean-and-paste"
        }
    }

    var permissionGuidance: PermissionGuidance? {
        switch self {
        case .automationPermissionRequired:
            return PermissionGuidance(
                title: "Hotkey blocked by Accessibility permission",
                detail: "Enable ClipPolish in macOS Accessibility settings, then retry.",
                settingsPath: "System Settings -> Privacy & Security -> Accessibility",
                actionTitle: "Request Accessibility Permission"
            )
        case .automationPermissionRequestDenied:
            return PermissionGuidance(
                title: "Accessibility permission not granted yet",
                detail: "Approve ClipPolish in macOS Accessibility settings, then retry.",
                settingsPath: "System Settings -> Privacy & Security -> Accessibility",
                actionTitle: "Request Accessibility Permission"
            )
        case .noPlainText, .alreadyClean, .cleaned, .clipboardReadFailed, .clipboardWriteFailed, .automationPermissionGranted:
            return nil
        }
    }

    static func fromCleanupResult(_ result: CleanupResult) -> StatusMessage {
        switch result {
        case let .cleaned(summary):
            return .cleaned(totalCharactersRemoved: summary.totalCharactersRemoved)
        case .alreadyClean:
            return .alreadyClean
        case .noPlainText:
            return .noPlainText
        case .clipboardReadFailed:
            return .clipboardReadFailed
        case .clipboardWriteFailed:
            return .clipboardWriteFailed
        }
    }
}

struct PermissionGuidance: Equatable, Sendable {
    let title: String
    let detail: String
    let settingsPath: String
    let actionTitle: String
}
