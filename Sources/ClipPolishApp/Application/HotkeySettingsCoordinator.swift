import KeyboardShortcuts

enum HotkeyShortcutUpdateOutcome: Equatable {
    case accepted
    case blockedConflict(suggestions: [String])
    case invalidShortcut
}

struct HotkeySettingsState: Equatable {
    var isEnabled: Bool
    var shortcut: KeyboardShortcuts.Shortcut?

    var statusText: String {
        let stateText = isEnabled ? "Enabled" : "Disabled"
        let shortcutText = shortcut.map { "\($0)" } ?? "Not set"
        return "Hotkey: \(stateText) (\(shortcutText))"
    }
}

@MainActor
final class HotkeySettingsCoordinator {
    private let store: HotkeyPreferencesStoring
    private let hotkeyService: GlobalHotkeyServing
    private let defaultShortcut: KeyboardShortcuts.Shortcut

    init(
        store: HotkeyPreferencesStoring,
        hotkeyService: GlobalHotkeyServing,
        defaultShortcut: KeyboardShortcuts.Shortcut = HotkeyPreferenceDefaults.defaultShortcut
    ) {
        self.store = store
        self.hotkeyService = hotkeyService
        self.defaultShortcut = defaultShortcut
    }

    func applyStoredSettings() {
        let preferences = store.load()
        hotkeyService.apply(
            isEnabled: preferences.isEnabled,
            shortcut: preferences.shortcut
        )
    }

    func currentSettings() -> HotkeySettingsState {
        let preferences = store.load()
        return HotkeySettingsState(
            isEnabled: preferences.isEnabled,
            shortcut: preferences.shortcut
        )
    }

    func setHotkeyEnabled(_ isEnabled: Bool) {
        if isEnabled {
            enableHotkey()
            return
        }

        store.setHotkeyEnabled(false)
        hotkeyService.unregister()
    }

    func setShortcut(_ shortcut: KeyboardShortcuts.Shortcut?) -> HotkeyShortcutUpdateOutcome {
        guard let shortcut else {
            return .invalidShortcut
        }

        return setShortcut(shortcut)
    }

    func setShortcut(_ shortcut: KeyboardShortcuts.Shortcut) -> HotkeyShortcutUpdateOutcome {
        switch hotkeyService.validate(shortcut: shortcut) {
        case .accepted:
            store.setShortcut(shortcut)
            let preferences = store.load()
            hotkeyService.apply(
                isEnabled: preferences.isEnabled,
                shortcut: preferences.shortcut
            )

            return .accepted
        case .blockedConflict(let suggestions):
            if suggestions.isEmpty {
                return .blockedConflict(suggestions: Self.defaultConflictSuggestions)
            }

            return .blockedConflict(suggestions: suggestions)
        case .invalidShortcut:
            return .invalidShortcut
        }
    }

    private func enableHotkey() {
        let preferences = store.load()
        let shortcut = preferences.shortcut ?? defaultShortcut

        if preferences.shortcut == nil {
            store.setShortcut(shortcut)
        }

        store.setHotkeyEnabled(true)
        hotkeyService.register(shortcut: shortcut)
    }

    private static let defaultConflictSuggestions = [
        "Try Command-Shift-Option-V",
        "Try Command-Option-V",
        "Try Control-Shift-V"
    ]
}
