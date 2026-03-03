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
    func preflightPostEventAccess() -> Bool {
        CGPreflightPostEventAccess()
    }

    func requestPostEventAccess() -> Bool {
        CGRequestPostEventAccess()
    }
}
