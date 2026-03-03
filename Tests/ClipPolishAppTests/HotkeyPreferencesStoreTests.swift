import Foundation
import KeyboardShortcuts
import Testing
@testable import ClipPolishApp

struct HotkeyPreferencesStoreTests {
    @Test
    func storePersistsOnlyOperationalKeysAndRoundTripsValues() {
        let suiteName = "HotkeyPreferencesStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = HotkeyPreferencesStore(userDefaults: defaults)
        let shortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .shift, .option])

        store.save(
            HotkeyPreferences(
                isEnabled: true,
                shortcut: shortcut
            )
        )

        let loaded = store.load()
        #expect(loaded.isEnabled)
        #expect(loaded.shortcut == shortcut)

        let persistedOperationalKeys = Set(
            defaults.dictionaryRepresentation().keys.filter {
                $0.hasPrefix("hotkey.")
            }
        )
        #expect(
            persistedOperationalKeys == [
                HotkeyPreferencesStore.Keys.enabled,
                HotkeyPreferencesStore.Keys.shortcut
            ]
        )
    }
}
