import Foundation
import KeyboardShortcuts

struct HotkeyPreferences: Equatable {
    var isEnabled: Bool
    var shortcut: KeyboardShortcuts.Shortcut?
}

protocol HotkeyPreferencesStoring: Sendable {
    func load() -> HotkeyPreferences
    func save(_ preferences: HotkeyPreferences)
    func setHotkeyEnabled(_ isEnabled: Bool)
    func setShortcut(_ shortcut: KeyboardShortcuts.Shortcut?)
}

enum HotkeyPreferenceDefaults {
    static let defaultShortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .shift, .option])
}

final class HotkeyPreferencesStore: HotkeyPreferencesStoring, @unchecked Sendable {
    enum Keys {
        static let enabled = "hotkey.enabled"
        static let shortcut = "hotkey.shortcut"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> HotkeyPreferences {
        HotkeyPreferences(
            isEnabled: userDefaults.bool(forKey: Keys.enabled),
            shortcut: loadShortcut()
        )
    }

    func save(_ preferences: HotkeyPreferences) {
        setHotkeyEnabled(preferences.isEnabled)
        setShortcut(preferences.shortcut)
    }

    func setHotkeyEnabled(_ isEnabled: Bool) {
        userDefaults.set(isEnabled, forKey: Keys.enabled)
    }

    func setShortcut(_ shortcut: KeyboardShortcuts.Shortcut?) {
        guard let shortcut else {
            userDefaults.removeObject(forKey: Keys.shortcut)
            return
        }

        guard let encodedShortcut = try? JSONEncoder().encode(shortcut) else {
            return
        }

        userDefaults.set(encodedShortcut, forKey: Keys.shortcut)
    }

    private func loadShortcut() -> KeyboardShortcuts.Shortcut? {
        guard
            let data = userDefaults.data(forKey: Keys.shortcut),
            let shortcut = try? JSONDecoder().decode(KeyboardShortcuts.Shortcut.self, from: data)
        else {
            return nil
        }

        return shortcut
    }
}
