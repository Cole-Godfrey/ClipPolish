import ClipPolishCore
import Foundation
import SwiftUI

@main
struct ClipPolishApp: App {
    @StateObject private var statusPresenter: StatusPresenter
    private let menuActionCoordinator: MenuActionCoordinator
    private let hotkeyExecutionCoordinator: HotkeyExecutionCoordinator
    private let hotkeySettingsCoordinator: HotkeySettingsCoordinator
    private let initialHotkeySettings: HotkeySettingsState

    init() {
        let environment = ProcessInfo.processInfo.environment
        let smokeDiagnosticsSink = HotkeySmokeDiagnosticsFileSink(environment: environment)
        let presenter = StatusPresenter(smokeDiagnosticsSink: smokeDiagnosticsSink)
        _statusPresenter = StateObject(wrappedValue: presenter)

        let cleanupService = CleanupService(gateway: SystemPasteboardGateway())
        menuActionCoordinator = MenuActionCoordinator(
            cleanupService: cleanupService,
            statusPresenter: presenter
        )

        let hotkeyPreferencesStore = HotkeyPreferencesStore()
        let hotkeyService = GlobalHotkeyService()
        let settingsCoordinator = HotkeySettingsCoordinator(
            store: hotkeyPreferencesStore,
            hotkeyService: hotkeyService
        )

        let permissionService = AutomationPermissionService(environment: environment)
        let pastePoster = CoreGraphicsPasteEventPoster()
        let executionCoordinator = HotkeyExecutionCoordinator(
            cleanupService: cleanupService,
            permissionService: permissionService,
            pastePoster: pastePoster,
            statusPresenter: presenter,
            smokeDiagnosticsSink: smokeDiagnosticsSink,
            isHotkeyEnabledProvider: {
                settingsCoordinator.currentSettings().isEnabled
            }
        )
        hotkeyExecutionCoordinator = executionCoordinator

        hotkeyService.bindHotkeyHandler {
            executionCoordinator.runHotkeyCleanAndPaste()
        }
        settingsCoordinator.applyStoredSettings()
        hotkeySettingsCoordinator = settingsCoordinator
        initialHotkeySettings = settingsCoordinator.currentSettings()
    }

    var body: some Scene {
        MenuBarScene(
            statusPresenter: statusPresenter,
            initialHotkeySettings: initialHotkeySettings,
            onCleanClipboardText: { menuActionCoordinator.runManualCleanup() },
            onHotkeyEnabledChanged: { isEnabled in
                hotkeySettingsCoordinator.setHotkeyEnabled(isEnabled)
            },
            onHotkeyShortcutChanged: { shortcut in
                hotkeySettingsCoordinator.setShortcut(shortcut)
            },
            currentHotkeySettings: {
                hotkeySettingsCoordinator.currentSettings()
            },
            onRequestAutomationPermission: {
                hotkeyExecutionCoordinator.requestAutomationPermissionIfNeeded()
            },
            onOpenAccessibilitySettings: {
                hotkeyExecutionCoordinator.openAccessibilitySettings()
            }
        )
    }
}
