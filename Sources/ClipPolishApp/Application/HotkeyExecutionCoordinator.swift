import AppKit
import ClipPolishCore
import Foundation

@MainActor
final class HotkeyExecutionCoordinator {
    private let cleanupService: any ClipboardCleanupServing
    private let permissionService: any AutomationPermissionServing
    private let pastePoster: any PasteEventPosting
    private let statusPresenter: any StatusMessagePresenting
    private let frontmostApplicationPIDProvider: @MainActor @Sendable () -> pid_t?
    private var activeExecution: Task<Void, Never>?

    init(
        cleanupService: any ClipboardCleanupServing,
        permissionService: any AutomationPermissionServing,
        pastePoster: any PasteEventPosting,
        statusPresenter: any StatusMessagePresenting,
        frontmostApplicationPIDProvider: @escaping @MainActor @Sendable () -> pid_t? = {
            NSWorkspace.shared.frontmostApplication?.processIdentifier
        }
    ) {
        self.cleanupService = cleanupService
        self.permissionService = permissionService
        self.pastePoster = pastePoster
        self.statusPresenter = statusPresenter
        self.frontmostApplicationPIDProvider = frontmostApplicationPIDProvider
    }

    func runHotkeyCleanAndPaste() {
        guard activeExecution == nil else {
            return
        }

        let targetPID = frontmostApplicationPIDProvider()
        guard permissionService.preflightPostEventAccess() else {
            statusPresenter.show(.automationPermissionRequired)
            return
        }

        activeExecution = Task { @MainActor [self, targetPID] in
            defer {
                activeExecution = nil
            }

            let cleanupResult = cleanupService.cleanCurrentClipboardText()
            if Self.shouldPostPaste(for: cleanupResult) {
                pastePoster.postPaste(targetPID: targetPID)
            }
            statusPresenter.show(.fromCleanupResult(cleanupResult))
        }
    }

    func requestAutomationPermissionIfNeeded() {
        guard activeExecution == nil else {
            return
        }

        guard !permissionService.preflightPostEventAccess() else {
            statusPresenter.show(.automationPermissionGranted)
            return
        }

        let granted = permissionService.requestPostEventAccess()
        statusPresenter.show(granted ? .automationPermissionGranted : .automationPermissionRequestDenied)
    }

    private static func shouldPostPaste(for cleanupResult: CleanupResult) -> Bool {
        switch cleanupResult {
        case .cleaned, .alreadyClean:
            return true
        case .noPlainText, .clipboardReadFailed, .clipboardWriteFailed:
            return false
        }
    }
}
