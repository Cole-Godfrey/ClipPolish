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
    private let requestPostEventAccessProvider: @Sendable () -> Bool
    private let preflightAccessibilityTrustProvider: @Sendable () -> Bool
    private let requestAccessibilityTrustProvider: @Sendable () -> Bool

    init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        preflightPostEventAccessProvider: @escaping @Sendable () -> Bool = { CGPreflightPostEventAccess() },
        requestPostEventAccessProvider: @escaping @Sendable () -> Bool = { CGRequestPostEventAccess() },
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
        self.requestPostEventAccessProvider = requestPostEventAccessProvider
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

        if requestPostEventAccessProvider() {
            return true
        }

        if requestAccessibilityTrustProvider() {
            return true
        }

        return preflightPostEventAccess()
    }
}
