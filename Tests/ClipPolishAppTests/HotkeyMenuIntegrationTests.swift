import Foundation
import KeyboardShortcuts
import Testing
@testable import ClipPolishApp

@MainActor
struct HotkeyMenuIntegrationTests {
    @Test
    func enableDisableFlowPreservesShortcutAcrossReEnable() {
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

        #expect(coordinator.setShortcut(selectedShortcut) == .accepted)
        coordinator.setHotkeyEnabled(true)
        coordinator.setHotkeyEnabled(false)
        coordinator.setHotkeyEnabled(true)

        let current = coordinator.currentSettings()
        #expect(current.isEnabled)
        #expect(current.shortcut == selectedShortcut)
        #expect(hotkeyService.registeredShortcuts == [selectedShortcut, selectedShortcut])
        #expect(hotkeyService.unregisterCallCount == 1)
    }

    @Test
    func conflictingShortcutDoesNotOverwriteLastValidValue() {
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
        hotkeyService.validationResult = .blockedConflict(
            suggestions: [
                "Try Command-Shift-Option-V",
                "Try Command-Option-V"
            ]
        )

        let coordinator = HotkeySettingsCoordinator(
            store: store,
            hotkeyService: hotkeyService
        )

        let outcome = coordinator.setShortcut(attemptedShortcut)

        #expect(
            outcome == .blockedConflict(
                suggestions: [
                    "Try Command-Shift-Option-V",
                    "Try Command-Option-V"
                ]
            )
        )
        #expect(store.load().shortcut == existingShortcut)
        #expect(hotkeyService.registeredShortcuts.isEmpty)
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

    func apply(isEnabled: Bool, shortcut: KeyboardShortcuts.Shortcut?) {
        applyCalls.append(
            ApplyCall(
                isEnabled: isEnabled,
                shortcut: shortcut
            )
        )
    }

    func validate(shortcut: KeyboardShortcuts.Shortcut) -> HotkeyShortcutValidationResult {
        validationResult
    }
}
