import ClipPolishCore
import SwiftUI

@main
struct ClipPolishApp: App {
    @StateObject private var statusPresenter: StatusPresenter
    private let menuActionCoordinator: MenuActionCoordinator
    private let hotkeyExecutionCoordinator: HotkeyExecutionCoordinator
    private let hotkeySettingsCoordinator: HotkeySettingsCoordinator
    private let initialHotkeySettings: HotkeySettingsState

    init() {
        let presenter = StatusPresenter()
        _statusPresenter = StateObject(wrappedValue: presenter)

        let cleanupService = CleanupService(gateway: SystemPasteboardGateway())
        menuActionCoordinator = MenuActionCoordinator(
            cleanupService: cleanupService,
            statusPresenter: presenter
        )

        let permissionService = AutomationPermissionService()
        let pastePoster = CoreGraphicsPasteEventPoster()
        let executionCoordinator = HotkeyExecutionCoordinator(
            cleanupService: cleanupService,
            permissionService: permissionService,
            pastePoster: pastePoster,
            statusPresenter: presenter
        )
        hotkeyExecutionCoordinator = executionCoordinator

        let hotkeyPreferencesStore = HotkeyPreferencesStore()
        let hotkeyService = GlobalHotkeyService()
        hotkeyService.bindHotkeyHandler {
            executionCoordinator.runHotkeyCleanAndPaste()
        }
        let settingsCoordinator = HotkeySettingsCoordinator(
            store: hotkeyPreferencesStore,
            hotkeyService: hotkeyService
        )
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
            onRequestAutomationPermission: {
                hotkeyExecutionCoordinator.requestAutomationPermissionIfNeeded()
            },
            onOpenAccessibilitySettings: {
                hotkeyExecutionCoordinator.openAccessibilitySettings()
            }
        )
    }
}
