import KeyboardShortcuts
import Testing
@testable import ClipPolishApp

@MainActor
struct HotkeySettingsCoordinatorTests {
    @Test
    func enablingWithoutExistingShortcutPersistsDefaultAndRegistersInOrder() {
        let eventLog = SharedEventLog()
        let store = InMemoryHotkeyPreferencesStore(
            initial: HotkeyPreferences(isEnabled: false, shortcut: nil),
            eventLog: eventLog
        )
        let service = RecordingGlobalHotkeyService(eventLog: eventLog)
        let coordinator = HotkeySettingsCoordinator(
            store: store,
            hotkeyService: service
        )

        coordinator.setHotkeyEnabled(true)

        let defaultShortcut = HotkeyPreferenceDefaults.defaultShortcut
        #expect(store.current.isEnabled)
        #expect(store.current.shortcut == defaultShortcut)
        #expect(service.registeredShortcuts == [defaultShortcut])
        #expect(
            eventLog.events
                == [
                    .setShortcut(defaultShortcut),
                    .setEnabled(true),
                    .register(defaultShortcut)
                ]
        )
    }

    @Test
    func disablingUnregistersWithoutClearingPersistedShortcut() {
        let eventLog = SharedEventLog()
        let configuredShortcut = KeyboardShortcuts.Shortcut(.k, modifiers: [.command, .option])
        let store = InMemoryHotkeyPreferencesStore(
            initial: HotkeyPreferences(isEnabled: true, shortcut: configuredShortcut),
            eventLog: eventLog
        )
        let service = RecordingGlobalHotkeyService(eventLog: eventLog)
        let coordinator = HotkeySettingsCoordinator(
            store: store,
            hotkeyService: service
        )

        coordinator.setHotkeyEnabled(false)

        #expect(store.current.isEnabled == false)
        #expect(store.current.shortcut == configuredShortcut)
        #expect(service.unregisterCallCount == 1)
    }

    @Test
    func reEnableRegistersPersistedShortcut() {
        let eventLog = SharedEventLog()
        let configuredShortcut = KeyboardShortcuts.Shortcut(.c, modifiers: [.command, .shift])
        let store = InMemoryHotkeyPreferencesStore(
            initial: HotkeyPreferences(isEnabled: false, shortcut: configuredShortcut),
            eventLog: eventLog
        )
        let service = RecordingGlobalHotkeyService(eventLog: eventLog)
        let coordinator = HotkeySettingsCoordinator(
            store: store,
            hotkeyService: service
        )

        coordinator.setHotkeyEnabled(true)

        #expect(service.registeredShortcuts == [configuredShortcut])
    }

    @Test
    func acceptedShortcutWhileDisabledPersistsAndUnregistersRuntime() {
        let eventLog = SharedEventLog()
        let configuredShortcut = KeyboardShortcuts.Shortcut(.k, modifiers: [.command, .option])
        let store = InMemoryHotkeyPreferencesStore(
            initial: HotkeyPreferences(isEnabled: false, shortcut: configuredShortcut),
            eventLog: eventLog
        )
        let service = RecordingGlobalHotkeyService(eventLog: eventLog)
        let coordinator = HotkeySettingsCoordinator(
            store: store,
            hotkeyService: service
        )
        let replacementShortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .shift, .option])

        let outcome = coordinator.setShortcut(replacementShortcut)

        #expect(outcome == .accepted)
        #expect(store.current.isEnabled == false)
        #expect(store.current.shortcut == replacementShortcut)
        #expect(service.registeredShortcuts.isEmpty)
        #expect(service.unregisterCallCount == 1)
        #expect(
            eventLog.events
                == [
                    .setShortcut(replacementShortcut),
                    .unregister
                ]
        )
    }

    @Test
    func acceptedShortcutWhileEnabledPersistsAndRegistersRuntime() {
        let eventLog = SharedEventLog()
        let configuredShortcut = KeyboardShortcuts.Shortcut(.k, modifiers: [.command, .option])
        let store = InMemoryHotkeyPreferencesStore(
            initial: HotkeyPreferences(isEnabled: true, shortcut: configuredShortcut),
            eventLog: eventLog
        )
        let service = RecordingGlobalHotkeyService(eventLog: eventLog)
        let coordinator = HotkeySettingsCoordinator(
            store: store,
            hotkeyService: service
        )
        let replacementShortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .shift, .option])

        let outcome = coordinator.setShortcut(replacementShortcut)

        #expect(outcome == .accepted)
        #expect(store.current.isEnabled)
        #expect(store.current.shortcut == replacementShortcut)
        #expect(service.registeredShortcuts == [replacementShortcut])
        #expect(service.unregisterCallCount == 0)
    }

    @Test
    func applyStoredSettingsWithDisabledPersistedShortcutKeepsRuntimeInactive() {
        let eventLog = SharedEventLog()
        let configuredShortcut = KeyboardShortcuts.Shortcut(.k, modifiers: [.command, .option])
        let store = InMemoryHotkeyPreferencesStore(
            initial: HotkeyPreferences(isEnabled: false, shortcut: configuredShortcut),
            eventLog: eventLog
        )
        let service = RecordingGlobalHotkeyService(eventLog: eventLog)
        let coordinator = HotkeySettingsCoordinator(
            store: store,
            hotkeyService: service
        )

        coordinator.applyStoredSettings()

        #expect(service.applyInvocations.count == 1)
        #expect(service.applyInvocations[0].isEnabled == false)
        #expect(service.applyInvocations[0].shortcut == configuredShortcut)
        #expect(service.registeredShortcuts.isEmpty)
        #expect(service.unregisterCallCount == 1)
    }

    @Test
    func blockedConflictKeepsPersistedShortcutAndReconcilesRuntimeFromStore() {
        let eventLog = SharedEventLog()
        let existingShortcut = KeyboardShortcuts.Shortcut(.c, modifiers: [.command, .shift])
        let proposedShortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .shift])
        let store = InMemoryHotkeyPreferencesStore(
            initial: HotkeyPreferences(isEnabled: true, shortcut: existingShortcut),
            eventLog: eventLog
        )
        let service = RecordingGlobalHotkeyService(eventLog: eventLog)
        service.validationResult = .blockedConflict(
            suggestions: [
                "Try Command-Shift-Option-V",
                "Try Command-Option-V"
            ]
        )
        let coordinator = HotkeySettingsCoordinator(
            store: store,
            hotkeyService: service
        )

        let outcome = coordinator.setShortcut(proposedShortcut)

        #expect(
            outcome == .blockedConflict(
                suggestions: [
                    "Try Command-Shift-Option-V",
                    "Try Command-Option-V"
                ]
            )
        )
        #expect(store.current.shortcut == existingShortcut)
        #expect(service.applyInvocations.count == 1)
        #expect(service.applyInvocations[0].isEnabled)
        #expect(service.applyInvocations[0].shortcut == existingShortcut)
        #expect(service.registeredShortcuts == [existingShortcut])
    }

    @Test
    func blockedConflictWithEmptySuggestionsUsesDefaultListAndReconcilesRuntime() {
        let eventLog = SharedEventLog()
        let existingShortcut = KeyboardShortcuts.Shortcut(.k, modifiers: [.command, .option])
        let proposedShortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .shift])
        let store = InMemoryHotkeyPreferencesStore(
            initial: HotkeyPreferences(isEnabled: true, shortcut: existingShortcut),
            eventLog: eventLog
        )
        let service = RecordingGlobalHotkeyService(eventLog: eventLog)
        service.validationResult = .blockedConflict(suggestions: [])
        let coordinator = HotkeySettingsCoordinator(
            store: store,
            hotkeyService: service
        )

        let outcome = coordinator.setShortcut(proposedShortcut)

        #expect(
            outcome == .blockedConflict(
                suggestions: [
                    "Try Command-Shift-Option-V",
                    "Try Command-Option-V",
                    "Try Control-Shift-V"
                ]
            )
        )
        #expect(store.current.shortcut == existingShortcut)
        #expect(service.applyInvocations.count == 1)
        #expect(service.applyInvocations[0].isEnabled)
        #expect(service.applyInvocations[0].shortcut == existingShortcut)
        #expect(service.registeredShortcuts == [existingShortcut])
    }

    @Test
    func invalidShortcutKeepsPersistedShortcutAndReconcilesRuntimeFromStore() {
        let eventLog = SharedEventLog()
        let existingShortcut = KeyboardShortcuts.Shortcut(.c, modifiers: [.command, .shift])
        let proposedShortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.command])
        let store = InMemoryHotkeyPreferencesStore(
            initial: HotkeyPreferences(isEnabled: true, shortcut: existingShortcut),
            eventLog: eventLog
        )
        let service = RecordingGlobalHotkeyService(eventLog: eventLog)
        service.validationResult = .invalidShortcut
        let coordinator = HotkeySettingsCoordinator(
            store: store,
            hotkeyService: service
        )

        let outcome = coordinator.setShortcut(proposedShortcut)

        #expect(outcome == .invalidShortcut)
        #expect(store.current.shortcut == existingShortcut)
        #expect(service.applyInvocations.count == 1)
        #expect(service.applyInvocations[0].isEnabled)
        #expect(service.applyInvocations[0].shortcut == existingShortcut)
        #expect(service.registeredShortcuts == [existingShortcut])
    }
}

private final class InMemoryHotkeyPreferencesStore: HotkeyPreferencesStoring, @unchecked Sendable {
    private(set) var current: HotkeyPreferences
    private let eventLog: SharedEventLog

    init(initial: HotkeyPreferences, eventLog: SharedEventLog) {
        current = initial
        self.eventLog = eventLog
    }

    func load() -> HotkeyPreferences {
        current
    }

    func save(_ preferences: HotkeyPreferences) {
        current = preferences
    }

    func setHotkeyEnabled(_ isEnabled: Bool) {
        current.isEnabled = isEnabled
        eventLog.events.append(.setEnabled(isEnabled))
    }

    func setShortcut(_ shortcut: KeyboardShortcuts.Shortcut?) {
        guard let shortcut else {
            return
        }

        current.shortcut = shortcut
        eventLog.events.append(.setShortcut(shortcut))
    }
}

private final class RecordingGlobalHotkeyService: GlobalHotkeyServing, @unchecked Sendable {
    private let eventLog: SharedEventLog
    private(set) var registeredShortcuts: [KeyboardShortcuts.Shortcut] = []
    private(set) var unregisterCallCount: Int = 0
    private(set) var applyInvocations: [(isEnabled: Bool, shortcut: KeyboardShortcuts.Shortcut?)] = []
    var validationResult: HotkeyShortcutValidationResult = .accepted

    init(eventLog: SharedEventLog) {
        self.eventLog = eventLog
    }

    var selectedShortcut: KeyboardShortcuts.Shortcut? {
        registeredShortcuts.last
    }

    func register(shortcut: KeyboardShortcuts.Shortcut) {
        registeredShortcuts.append(shortcut)
        eventLog.events.append(.register(shortcut))
    }

    func unregister() {
        unregisterCallCount += 1
        eventLog.events.append(.unregister)
    }

    func bindHotkeyHandler(_ handler: @escaping @MainActor @Sendable () -> Void) {}

    func apply(isEnabled: Bool, shortcut: KeyboardShortcuts.Shortcut?) {
        applyInvocations.append((isEnabled: isEnabled, shortcut: shortcut))

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

private final class SharedEventLog: @unchecked Sendable {
    enum Event: Equatable {
        case setEnabled(Bool)
        case setShortcut(KeyboardShortcuts.Shortcut)
        case register(KeyboardShortcuts.Shortcut)
        case unregister
    }

    var events: [Event] = []
}
