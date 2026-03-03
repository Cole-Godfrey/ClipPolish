import KeyboardShortcuts

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

    func setHotkeyEnabled(_ isEnabled: Bool) {
        if isEnabled {
            enableHotkey()
            return
        }

        store.setHotkeyEnabled(false)
        hotkeyService.unregister()
    }

    func setShortcut(_ shortcut: KeyboardShortcuts.Shortcut?) {
        store.setShortcut(shortcut)

        guard
            store.load().isEnabled,
            let shortcut
        else {
            return
        }

        hotkeyService.register(shortcut: shortcut)
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
}
