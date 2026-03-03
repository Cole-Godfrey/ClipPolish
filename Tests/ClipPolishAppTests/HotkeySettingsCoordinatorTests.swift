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

    init(eventLog: SharedEventLog) {
        self.eventLog = eventLog
    }

    func register(shortcut: KeyboardShortcuts.Shortcut) {
        registeredShortcuts.append(shortcut)
        eventLog.events.append(.register(shortcut))
    }

    func unregister() {
        unregisterCallCount += 1
    }

    func apply(isEnabled: Bool, shortcut: KeyboardShortcuts.Shortcut?) {}

    func validate(shortcut: KeyboardShortcuts.Shortcut) -> HotkeyShortcutValidationResult {
        .accepted
    }
}

private final class SharedEventLog: @unchecked Sendable {
    enum Event: Equatable {
        case setEnabled(Bool)
        case setShortcut(KeyboardShortcuts.Shortcut)
        case register(KeyboardShortcuts.Shortcut)
    }

    var events: [Event] = []
}
