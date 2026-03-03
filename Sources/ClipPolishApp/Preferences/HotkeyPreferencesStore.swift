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
    static let enableKey = "hotkey.enabled"
    static let defaultShortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .shift, .option])
}
