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
    private let smokeDiagnosticsSink: (any HotkeySmokeDiagnosticsSinking)?
    private let isHotkeyEnabledProvider: @MainActor @Sendable () -> Bool
    private let accessibilitySettingsOpener: @MainActor () -> Void
    private let appRestarter: @MainActor () -> Void
    private let frontmostApplicationPIDProvider: @MainActor @Sendable () -> pid_t?
    private var activeExecution: Task<Void, Never>?

    init(
        cleanupService: any ClipboardCleanupServing,
        permissionService: any AutomationPermissionServing,
        pastePoster: any PasteEventPosting,
        statusPresenter: any StatusMessagePresenting,
        smokeDiagnosticsSink: (any HotkeySmokeDiagnosticsSinking)? = nil,
        isHotkeyEnabledProvider: @escaping @MainActor @Sendable () -> Bool = { true },
        accessibilitySettingsOpener: @escaping @MainActor () -> Void = {
            guard let settingsURL = URL(string: HotkeyExecutionCoordinator.accessibilitySettingsURLString) else {
                return
            }
            NSWorkspace.shared.open(settingsURL)
        },
        appRestarter: @escaping @MainActor () -> Void = {
            var didLaunchReplacement = false

            if Bundle.main.bundleURL.pathExtension == "app" {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                process.arguments = ["-n", Bundle.main.bundlePath]
                do {
                    try process.run()
                    didLaunchReplacement = true
                } catch {
                    didLaunchReplacement = false
                }
            } else if let executableURL = Bundle.main.executableURL {
                let process = Process()
                process.executableURL = executableURL
                process.arguments = Array(CommandLine.arguments.dropFirst())
                do {
                    try process.run()
                    didLaunchReplacement = true
                } catch {
                    didLaunchReplacement = false
                }
            }

            guard didLaunchReplacement else {
                return
            }

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                NSApplication.shared.terminate(nil)
            }
        },
        frontmostApplicationPIDProvider: @escaping @MainActor @Sendable () -> pid_t? = {
            NSWorkspace.shared.frontmostApplication?.processIdentifier
        }
    ) {
        self.cleanupService = cleanupService
        self.permissionService = permissionService
        self.pastePoster = pastePoster
        self.statusPresenter = statusPresenter
        self.smokeDiagnosticsSink = smokeDiagnosticsSink
        self.isHotkeyEnabledProvider = isHotkeyEnabledProvider
        self.accessibilitySettingsOpener = accessibilitySettingsOpener
        self.appRestarter = appRestarter
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
                smokeDiagnosticsSink?.record(event: "hotkey.permission=denied")
                smokeDiagnosticsSink?.record(event: "hotkey.cleanup=skipped")
                smokeDiagnosticsSink?.record(event: "hotkey.paste=skipped")
                statusPresenter.show(.automationPermissionRequired)
                return
            }
        }

        smokeDiagnosticsSink?.record(event: "hotkey.permission=granted")

        activeExecution = Task { @MainActor [self, targetPID] in
            defer {
                activeExecution = nil
            }

            let cleanupResult = cleanupService.cleanCurrentClipboardText()
            smokeDiagnosticsSink?.record(event: "hotkey.cleanup=\(Self.smokeCleanupToken(for: cleanupResult))")

            let shouldPostPaste = Self.shouldPostPaste(for: cleanupResult)
            if shouldPostPaste {
                pastePoster.postPaste(targetPID: targetPID)
            }
            smokeDiagnosticsSink?.record(event: shouldPostPaste ? "hotkey.paste=posted" : "hotkey.paste=skipped")
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

    func showAccessibilityGuidanceIfNeededOnStartup() {
        guard !permissionService.preflightPostEventAccess() else {
            return
        }

        guard !permissionService.requestPostEventAccess() else {
            return
        }

        statusPresenter.show(.automationPermissionRequired)
        openAccessibilitySettings()
    }

    func openAccessibilitySettings() {
        accessibilitySettingsOpener()
    }

    func restartApplication() {
        appRestarter()
    }

    private static func shouldPostPaste(for cleanupResult: CleanupResult) -> Bool {
        switch cleanupResult {
        case .cleaned, .alreadyClean:
            return true
        case .noPlainText, .clipboardReadFailed, .clipboardWriteFailed:
            return false
        }
    }

    private static func smokeCleanupToken(for cleanupResult: CleanupResult) -> String {
        switch cleanupResult {
        case .cleaned:
            return "cleaned"
        case .alreadyClean:
            return "alreadyClean"
        case .noPlainText:
            return "noPlainText"
        case .clipboardReadFailed:
            return "clipboardReadFailed"
        case .clipboardWriteFailed:
            return "clipboardWriteFailed"
        }
    }
}
