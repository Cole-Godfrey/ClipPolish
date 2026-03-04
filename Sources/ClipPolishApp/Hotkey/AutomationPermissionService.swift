import ApplicationServices
import Foundation

@MainActor
protocol AutomationPermissionServing: Sendable {
    func preflightPostEventAccess() -> Bool
    func requestPostEventAccess() -> Bool
}

extension AutomationPermissionServing {
    func requestPostEventAccess() -> Bool {
        preflightPostEventAccess()
    }
}

struct AutomationPermissionService: AutomationPermissionServing {
    private enum SmokePermissionMode {
        case live
        case deny
    }

    private let smokePermissionMode: SmokePermissionMode

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        let smokeEnabled = environment["CLIPPOLISH_RUN_HOTKEY_E2E"] == "1"
        let requestedMode = environment["CLIPPOLISH_SMOKE_PERMISSION_MODE"]?.lowercased()
        smokePermissionMode = smokeEnabled && requestedMode == "deny" ? .deny : .live
    }

    func preflightPostEventAccess() -> Bool {
        if smokePermissionMode == .deny {
            return false
        }
        return CGPreflightPostEventAccess()
    }

    func requestPostEventAccess() -> Bool {
        if smokePermissionMode == .deny {
            return false
        }
        return CGRequestPostEventAccess()
    }
}
