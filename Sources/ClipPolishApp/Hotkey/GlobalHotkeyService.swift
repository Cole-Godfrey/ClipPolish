import Foundation
import KeyboardShortcuts

protocol GlobalHotkeyServing: Sendable {
    func register(shortcut: KeyboardShortcuts.Shortcut)
    func unregister()
    func apply(isEnabled: Bool, shortcut: KeyboardShortcuts.Shortcut?)
    func validate(shortcut: KeyboardShortcuts.Shortcut) -> HotkeyShortcutValidationResult
}

enum HotkeyShortcutValidationResult: Equatable {
    case accepted
    case blockedConflict(suggestions: [String])
    case invalidShortcut
}

enum HotkeyShortcutName {
    static let cleanAndPaste = KeyboardShortcuts.Name("cleanAndPaste")
}
