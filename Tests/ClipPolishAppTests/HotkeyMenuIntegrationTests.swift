import Foundation
import KeyboardShortcuts
import Testing
@testable import ClipPolishApp

@MainActor
struct HotkeyMenuIntegrationTests {
    @Test
    func acceptedMenuShortcutUpdatePersistsAndSurvivesEnableDisableLifecycle() {
        let suiteName = "HotkeyMenuIntegrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = HotkeyPreferencesStore(userDefaults: defaults)
        let hotkeyService = StubGlobalHotkeyService()
        let coordinator = HotkeySettingsCoordinator(
            store: store,
            hotkeyService: hotkeyService
        )
        let selectedShortcut = KeyboardShortcuts.Shortcut(.k, modifiers: [.command, .option])
        let action = MenuBarAction(
            runManualCleanup: {},
            setHotkeyEnabled: coordinator.setHotkeyEnabled,
            setHotkeyShortcut: coordinator.setShortcut,
            currentHotkeySettings: coordinator.currentSettings
        )

        #expect(action.hotkeyShortcutChanged(selectedShortcut) == .accepted)
        action.hotkeyEnabledChanged(true)
        action.hotkeyEnabledChanged(false)
        action.hotkeyEnabledChanged(true)

        let current = action.refreshedHotkeySettings()
        #expect(current?.isEnabled == true)
        #expect(current?.shortcut == selectedShortcut)
        #expect(store.load().shortcut == selectedShortcut)
        #expect(hotkeyService.registeredShortcuts == [selectedShortcut, selectedShortcut])
        #expect(hotkeyService.unregisterCallCount == 2)
    }

    @Test
    func invalidMenuShortcutUpdatePreservesPersistedShortcutAndRuntimeState() {
        let suiteName = "HotkeyMenuIntegrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let existingShortcut = KeyboardShortcuts.Shortcut(.c, modifiers: [.command, .shift])
        let attemptedShortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [])
        let store = HotkeyPreferencesStore(userDefaults: defaults)
        store.save(
            HotkeyPreferences(
                isEnabled: true,
                shortcut: existingShortcut
            )
        )

        let hotkeyService = StubGlobalHotkeyService()
        hotkeyService.validationResult = .invalidShortcut
        let coordinator = HotkeySettingsCoordinator(
            store: store,
            hotkeyService: hotkeyService
        )
        coordinator.applyStoredSettings()

        let action = MenuBarAction(
            runManualCleanup: {},
            setHotkeyEnabled: coordinator.setHotkeyEnabled,
            setHotkeyShortcut: coordinator.setShortcut,
            currentHotkeySettings: coordinator.currentSettings
        )

        let outcome = action.hotkeyShortcutChanged(attemptedShortcut)

        #expect(outcome == .invalidShortcut)
        #expect(store.load().shortcut == existingShortcut)
        #expect(action.refreshedHotkeySettings()?.shortcut == existingShortcut)
        #expect(
            hotkeyService.applyCalls
                == [
                    .init(isEnabled: true, shortcut: existingShortcut),
                    .init(isEnabled: true, shortcut: existingShortcut)
                ]
        )
        #expect(hotkeyService.registeredShortcuts == [existingShortcut, existingShortcut])
        #expect(hotkeyService.unregisterCallCount == 0)
    }

    @Test
    func conflictMenuShortcutUpdatePreservesShortcutAndReturnsDeterministicGuidance() {
        let suiteName = "HotkeyMenuIntegrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let existingShortcut = KeyboardShortcuts.Shortcut(.c, modifiers: [.command, .shift])
        let attemptedShortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .shift])
        let store = HotkeyPreferencesStore(userDefaults: defaults)
        store.save(
            HotkeyPreferences(
                isEnabled: true,
                shortcut: existingShortcut
            )
        )

        let hotkeyService = StubGlobalHotkeyService()
        hotkeyService.validationResult = .blockedConflict(suggestions: [])

        let coordinator = HotkeySettingsCoordinator(
            store: store,
            hotkeyService: hotkeyService
        )
        coordinator.applyStoredSettings()
        let action = MenuBarAction(
            runManualCleanup: {},
            setHotkeyEnabled: coordinator.setHotkeyEnabled,
            setHotkeyShortcut: coordinator.setShortcut,
            currentHotkeySettings: coordinator.currentSettings
        )

        let firstOutcome = action.hotkeyShortcutChanged(attemptedShortcut)
        let secondOutcome = action.hotkeyShortcutChanged(attemptedShortcut)

        #expect(
            firstOutcome == .blockedConflict(
                suggestions: [
                    "Try Command-Shift-Option-V",
                    "Try Command-Option-V",
                    "Try Control-Shift-V"
                ]
            )
        )
        #expect(
            secondOutcome == .blockedConflict(
                suggestions: [
                    "Try Command-Shift-Option-V",
                    "Try Command-Option-V",
                    "Try Control-Shift-V"
                ]
            )
        )
        #expect(store.load().shortcut == existingShortcut)
        #expect(action.refreshedHotkeySettings()?.shortcut == existingShortcut)
        #expect(hotkeyService.registeredShortcuts == [existingShortcut, existingShortcut, existingShortcut])
        #expect(
            hotkeyService.applyCalls
                == [
                    .init(isEnabled: true, shortcut: existingShortcut),
                    .init(isEnabled: true, shortcut: existingShortcut),
                    .init(isEnabled: true, shortcut: existingShortcut)
                ]
        )
    }

    @Test
    func relaunchBootstrapRehydratesEnabledStateAndShortcut() {
        let suiteName = "HotkeyMenuIntegrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let selectedShortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .shift, .option])
        HotkeyPreferencesStore(userDefaults: defaults).save(
            HotkeyPreferences(
                isEnabled: true,
                shortcut: selectedShortcut
            )
        )

        let relaunchedStore = HotkeyPreferencesStore(userDefaults: defaults)
        let relaunchedService = StubGlobalHotkeyService()
        let relaunchedCoordinator = HotkeySettingsCoordinator(
            store: relaunchedStore,
            hotkeyService: relaunchedService
        )

        relaunchedCoordinator.applyStoredSettings()
        let restored = relaunchedCoordinator.currentSettings()

        #expect(restored.isEnabled)
        #expect(restored.shortcut == selectedShortcut)
        #expect(
            relaunchedService.applyCalls
                == [
                    .init(
                        isEnabled: true,
                        shortcut: selectedShortcut
                    )
                ]
        )
    }

    @Test
    func relaunchBootstrapWithDisabledPersistedShortcutKeepsRuntimeInactive() {
        let suiteName = "HotkeyMenuIntegrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let selectedShortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .shift, .option])
        HotkeyPreferencesStore(userDefaults: defaults).save(
            HotkeyPreferences(
                isEnabled: false,
                shortcut: selectedShortcut
            )
        )

        let relaunchedStore = HotkeyPreferencesStore(userDefaults: defaults)
        let relaunchedService = StubGlobalHotkeyService()
        let relaunchedCoordinator = HotkeySettingsCoordinator(
            store: relaunchedStore,
            hotkeyService: relaunchedService
        )

        relaunchedCoordinator.applyStoredSettings()
        let restored = relaunchedCoordinator.currentSettings()

        #expect(restored.isEnabled == false)
        #expect(restored.shortcut == selectedShortcut)
        #expect(
            relaunchedService.applyCalls
                == [
                    .init(
                        isEnabled: false,
                        shortcut: selectedShortcut
                    )
                ]
        )
    }

    @Test
    func statusTextIsAlwaysDerivableFromCurrentSettingsState() {
        let disabledStateText = HotkeySettingsState(
            isEnabled: false,
            shortcut: nil
        ).statusText
        #expect(disabledStateText == "Hotkey: Disabled (Not set)")

        let enabledShortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .shift, .option])
        let enabledStateText = HotkeySettingsState(
            isEnabled: true,
            shortcut: enabledShortcut
        ).statusText
        #expect(enabledStateText == "Hotkey: Enabled (\(enabledShortcut))")
    }
}

@MainActor
private final class StubGlobalHotkeyService: GlobalHotkeyServing, @unchecked Sendable {
    struct ApplyCall: Equatable {
        let isEnabled: Bool
        let shortcut: KeyboardShortcuts.Shortcut?
    }

    private(set) var registeredShortcuts: [KeyboardShortcuts.Shortcut] = []
    private(set) var unregisterCallCount: Int = 0
    private(set) var applyCalls: [ApplyCall] = []
    var validationResult: HotkeyShortcutValidationResult = .accepted

    var selectedShortcut: KeyboardShortcuts.Shortcut? {
        registeredShortcuts.last ?? applyCalls.last?.shortcut
    }

    func register(shortcut: KeyboardShortcuts.Shortcut) {
        registeredShortcuts.append(shortcut)
    }

    func unregister() {
        unregisterCallCount += 1
    }

    func bindHotkeyHandler(_ handler: @escaping @MainActor @Sendable () -> Void) {}

    func apply(isEnabled: Bool, shortcut: KeyboardShortcuts.Shortcut?) {
        applyCalls.append(
            ApplyCall(
                isEnabled: isEnabled,
                shortcut: shortcut
            )
        )

        guard isEnabled, let shortcut else {
            unregister()
            return
        }

        register(shortcut: shortcut)
    }

    func validate(shortcut: KeyboardShortcuts.Shortcut) -> HotkeyShortcutValidationResult {
        validationResult
    }
}
