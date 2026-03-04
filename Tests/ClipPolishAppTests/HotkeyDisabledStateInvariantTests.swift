import Foundation
import KeyboardShortcuts
import Testing
@testable import ClipPolishApp

@MainActor
struct HotkeyDisabledStateInvariantTests {
    @Test
    func relaunchWithDisabledShortcutReconcilesExternalActivationBackToInactive() {
        let suiteName = "HotkeyDisabledStateInvariantTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let storedShortcut = KeyboardShortcuts.Shortcut(.k, modifiers: [.command, .option])
        let store = HotkeyPreferencesStore(userDefaults: defaults)
        store.save(
            HotkeyPreferences(
                isEnabled: false,
                shortcut: storedShortcut
            )
        )

        let service = InvariantRecordingHotkeyService()
        service.register(shortcut: storedShortcut) // Simulate third-party runtime activation side effect.
        #expect(service.isRuntimeActive)

        let coordinator = HotkeySettingsCoordinator(
            store: store,
            hotkeyService: service
        )

        coordinator.applyStoredSettings()

        let restored = coordinator.currentSettings()
        #expect(restored.isEnabled == false)
        #expect(restored.shortcut == storedShortcut)
        #expect(service.isRuntimeActive == false)
        #expect(service.unregisterCallCount == 1)
        #expect(
            service.applyCalls
                == [
                    .init(
                        isEnabled: false,
                        shortcut: storedShortcut
                    )
                ]
        )
    }

    @Test
    func shortcutEditWhileDisabledPersistsValueAndKeepsRuntimeInactive() {
        let suiteName = "HotkeyDisabledStateInvariantTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let existingShortcut = KeyboardShortcuts.Shortcut(.k, modifiers: [.command, .option])
        let replacementShortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .shift, .option])
        let store = HotkeyPreferencesStore(userDefaults: defaults)
        store.save(
            HotkeyPreferences(
                isEnabled: false,
                shortcut: existingShortcut
            )
        )

        let service = InvariantRecordingHotkeyService()
        service.register(shortcut: existingShortcut) // Simulate leaked listener activation before reconciliation.
        let coordinator = HotkeySettingsCoordinator(
            store: store,
            hotkeyService: service
        )

        let outcome = coordinator.setShortcut(replacementShortcut)

        #expect(outcome == .accepted)
        #expect(store.load().isEnabled == false)
        #expect(store.load().shortcut == replacementShortcut)
        #expect(service.isRuntimeActive == false)
        #expect(service.unregisterCallCount == 1)
        #expect(service.registeredShortcuts == [existingShortcut])
        #expect(
            service.applyCalls
                == [
                    .init(
                        isEnabled: false,
                        shortcut: replacementShortcut
                    )
                ]
        )
    }

    @Test
    func reEnableAfterDisabledEditRegistersPersistedShortcutExactlyOnce() {
        let suiteName = "HotkeyDisabledStateInvariantTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let existingShortcut = KeyboardShortcuts.Shortcut(.k, modifiers: [.command, .option])
        let replacementShortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .shift, .option])
        let store = HotkeyPreferencesStore(userDefaults: defaults)
        store.save(
            HotkeyPreferences(
                isEnabled: false,
                shortcut: existingShortcut
            )
        )

        let service = InvariantRecordingHotkeyService()
        let coordinator = HotkeySettingsCoordinator(
            store: store,
            hotkeyService: service
        )

        #expect(coordinator.setShortcut(replacementShortcut) == .accepted)
        coordinator.setHotkeyEnabled(true)

        let restored = coordinator.currentSettings()
        #expect(restored.isEnabled)
        #expect(restored.shortcut == replacementShortcut)
        #expect(service.registeredShortcuts == [replacementShortcut])
        #expect(service.unregisterCallCount == 1)
        #expect(service.isRuntimeActive)
    }
}

@MainActor
private final class InvariantRecordingHotkeyService: GlobalHotkeyServing, @unchecked Sendable {
    struct ApplyCall: Equatable {
        let isEnabled: Bool
        let shortcut: KeyboardShortcuts.Shortcut?
    }

    private(set) var registeredShortcuts: [KeyboardShortcuts.Shortcut] = []
    private(set) var unregisterCallCount: Int = 0
    private(set) var applyCalls: [ApplyCall] = []
    private(set) var isRuntimeActive: Bool = false
    var validationResult: HotkeyShortcutValidationResult = .accepted

    var selectedShortcut: KeyboardShortcuts.Shortcut? {
        registeredShortcuts.last
    }

    func register(shortcut: KeyboardShortcuts.Shortcut) {
        registeredShortcuts.append(shortcut)
        isRuntimeActive = true
    }

    func unregister() {
        unregisterCallCount += 1
        isRuntimeActive = false
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
