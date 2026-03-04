import KeyboardShortcuts
import Testing
@testable import ClipPolishApp

@MainActor
struct GlobalHotkeyServiceValidationTests {
    @Test
    func shortcutWithoutModifiersIsInvalid() {
        let service = GlobalHotkeyService(
            name: HotkeyShortcutName.cleanAndPaste,
            conflictDetector: StubHotkeyConflictDetector(conflict: nil)
        )
        let shortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [])

        let outcome = service.validate(shortcut: shortcut)

        #expect(outcome == .invalidShortcut)
    }

    @Test
    func systemConflictMapsToBlockedConflictWithDeterministicSuggestions() {
        let service = GlobalHotkeyService(
            name: HotkeyShortcutName.cleanAndPaste,
            conflictDetector: StubHotkeyConflictDetector(conflict: .systemReserved)
        )
        let shortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .option])

        let outcome = service.validate(shortcut: shortcut)

        #expect(
            outcome == .blockedConflict(
                suggestions: [
                    "Try Command-Shift-Option-V",
                    "Try Command-Option-V",
                    "Try Control-Shift-V"
                ]
            )
        )
    }

    @Test
    func appMenuConflictMapsToBlockedConflictWithDeterministicSuggestions() {
        let service = GlobalHotkeyService(
            name: HotkeyShortcutName.cleanAndPaste,
            conflictDetector: StubHotkeyConflictDetector(conflict: .appMenu)
        )
        let shortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .shift])

        let outcome = service.validate(shortcut: shortcut)

        #expect(
            outcome == .blockedConflict(
                suggestions: [
                    "Try Command-Shift-Option-V",
                    "Try Command-Option-V",
                    "Try Control-Option-V"
                ]
            )
        )
    }

    @Test
    func conflictFreeShortcutIsAccepted() {
        let service = GlobalHotkeyService(
            name: HotkeyShortcutName.cleanAndPaste,
            conflictDetector: StubHotkeyConflictDetector(conflict: nil)
        )
        let shortcut = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .shift, .option])

        let outcome = service.validate(shortcut: shortcut)

        #expect(outcome == .accepted)
    }
}

private struct StubHotkeyConflictDetector: HotkeyConflictDetecting {
    let conflict: HotkeyConflict?

    func conflict(for shortcut: KeyboardShortcuts.Shortcut) -> HotkeyConflict? {
        conflict
    }
}
