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
    private let preflightPostEventAccessProvider: @Sendable () -> Bool
    private let preflightAccessibilityTrustProvider: @Sendable () -> Bool
    private let requestAccessibilityTrustProvider: @Sendable () -> Bool

    init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        preflightPostEventAccessProvider: @escaping @Sendable () -> Bool = { CGPreflightPostEventAccess() },
        preflightAccessibilityTrustProvider: @escaping @Sendable () -> Bool = { AXIsProcessTrusted() },
        requestAccessibilityTrustProvider: @escaping @Sendable () -> Bool = {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }
    ) {
        let smokeEnabled = environment["CLIPPOLISH_RUN_HOTKEY_E2E"] == "1"
        let requestedMode = environment["CLIPPOLISH_SMOKE_PERMISSION_MODE"]?.lowercased()
        smokePermissionMode = smokeEnabled && requestedMode == "deny" ? .deny : .live
        self.preflightPostEventAccessProvider = preflightPostEventAccessProvider
        self.preflightAccessibilityTrustProvider = preflightAccessibilityTrustProvider
        self.requestAccessibilityTrustProvider = requestAccessibilityTrustProvider
    }

    func preflightPostEventAccess() -> Bool {
        if smokePermissionMode == .deny {
            return false
        }
        return preflightPostEventAccessProvider() || preflightAccessibilityTrustProvider()
    }

    func requestPostEventAccess() -> Bool {
        if smokePermissionMode == .deny {
            return false
        }

        if preflightPostEventAccess() {
            return true
        }

        // Use a single prompting API per request attempt to avoid duplicate
        // permission dialogs in one launch flow.
        if requestAccessibilityTrustProvider() {
            return true
        }

        return preflightPostEventAccess()
    }
}
