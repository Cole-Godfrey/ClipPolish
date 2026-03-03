import ApplicationServices
import Foundation

@MainActor
protocol AutomationPermissionServing: Sendable {
    func preflightPostEventAccess() -> Bool
}

struct AutomationPermissionService: AutomationPermissionServing {
    func preflightPostEventAccess() -> Bool {
        CGPreflightPostEventAccess()
    }
}
