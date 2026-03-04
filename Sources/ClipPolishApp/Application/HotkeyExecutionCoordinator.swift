import AppKit
import ClipPolishCore
import Foundation

@MainActor
final class HotkeyExecutionCoordinator {
    private static let accessibilitySettingsURLString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

    private let cleanupService: any ClipboardCleanupServing
    private let permissionService: any AutomationPermissionServing
    private let pastePoster: any PasteEventPosting
    private let statusPresenter: any StatusMessagePresenting
    private let isHotkeyEnabledProvider: @MainActor @Sendable () -> Bool
    private let accessibilitySettingsOpener: @MainActor () -> Void
    private let frontmostApplicationPIDProvider: @MainActor @Sendable () -> pid_t?
    private var activeExecution: Task<Void, Never>?

    init(
        cleanupService: any ClipboardCleanupServing,
        permissionService: any AutomationPermissionServing,
        pastePoster: any PasteEventPosting,
        statusPresenter: any StatusMessagePresenting,
        isHotkeyEnabledProvider: @escaping @MainActor @Sendable () -> Bool = { true },
        accessibilitySettingsOpener: @escaping @MainActor () -> Void = {
            guard let settingsURL = URL(string: HotkeyExecutionCoordinator.accessibilitySettingsURLString) else {
                return
            }
            NSWorkspace.shared.open(settingsURL)
        },
        frontmostApplicationPIDProvider: @escaping @MainActor @Sendable () -> pid_t? = {
            NSWorkspace.shared.frontmostApplication?.processIdentifier
        }
    ) {
        self.cleanupService = cleanupService
        self.permissionService = permissionService
        self.pastePoster = pastePoster
        self.statusPresenter = statusPresenter
        self.isHotkeyEnabledProvider = isHotkeyEnabledProvider
        self.accessibilitySettingsOpener = accessibilitySettingsOpener
        self.frontmostApplicationPIDProvider = frontmostApplicationPIDProvider
    }

    func runHotkeyCleanAndPaste() {
        guard activeExecution == nil else {
            return
        }

        guard isHotkeyEnabledProvider() else {
            return
        }

        let targetPID = frontmostApplicationPIDProvider()
        if !permissionService.preflightPostEventAccess() {
            guard permissionService.requestPostEventAccess() else {
                statusPresenter.show(.automationPermissionRequired)
                return
            }
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
        guard !granted else {
            return
        }

        openAccessibilitySettings()
    }

    func openAccessibilitySettings() {
        accessibilitySettingsOpener()
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
