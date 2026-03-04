import KeyboardShortcuts
import Testing
@testable import ClipPolishApp

struct MenuBarActionTests {
    @Test
    func cleanClipboardCommandInvokesHandlerOnce() {
        let recorder = InvocationRecorder()
        let action = MenuBarAction(runManualCleanup: {
            recorder.record()
        })

        action.cleanClipboardTextSelected()

        #expect(recorder.invocationCount == 1)
    }

    @Test
    func commandDoesNotCreateRepeatLoop() {
        let recorder = InvocationRecorder()
        let action = MenuBarAction(runManualCleanup: {
            recorder.record()
        })

        action.cleanClipboardTextSelected()
        action.cleanClipboardTextSelected()

        #expect(recorder.invocationCount == 2)
    }

    @Test
    func hotkeyToggleCommandInvokesHandlerWithProvidedValue() {
        let recorder = HotkeySettingsRecorder()
        let action = MenuBarAction(
            runManualCleanup: {},
            setHotkeyEnabled: { value in
                recorder.enabledValues.append(value)
            }
        )

        action.hotkeyEnabledChanged(true)
        action.hotkeyEnabledChanged(false)

        #expect(recorder.enabledValues == [true, false])
    }

    @Test
    func hotkeyShortcutCommandReturnsConfiguredOutcome() {
        let recorder = HotkeySettingsRecorder()
        let expectedShortcut = KeyboardShortcuts.Shortcut(.k, modifiers: [.command, .option])
        let action = MenuBarAction(
            runManualCleanup: {},
            setHotkeyShortcut: { shortcut in
                recorder.shortcuts.append(shortcut)
                return .blockedConflict(
                    suggestions: [
                        "Try Command-Shift-Option-V"
                    ]
                )
            }
        )

        let outcome = action.hotkeyShortcutChanged(expectedShortcut)

        #expect(
            outcome == .blockedConflict(
                suggestions: [
                    "Try Command-Shift-Option-V"
                ]
            )
        )
        #expect(recorder.shortcuts == [expectedShortcut])
    }

    @Test
    func defaultShortcutHandlerRejectsMissingShortcut() {
        let action = MenuBarAction(runManualCleanup: {})

        let outcome = action.hotkeyShortcutChanged(nil)

        #expect(outcome == .invalidShortcut)
    }

    @Test
    func requestPermissionCommandInvokesHandlerOnce() {
        let recorder = InvocationRecorder()
        let action = MenuBarAction(
            runManualCleanup: {},
            requestAutomationPermission: {
                recorder.record()
            }
        )

        action.requestAutomationPermissionSelected()

        #expect(recorder.invocationCount == 1)
    }

    @Test
    func openAccessibilitySettingsCommandInvokesHandlerOnce() {
        let recorder = InvocationRecorder()
        let action = MenuBarAction(
            runManualCleanup: {},
            openAccessibilitySettings: {
                recorder.record()
            }
        )

        action.openAccessibilitySettingsSelected()

        #expect(recorder.invocationCount == 1)
    }

    @Test
    func restartApplicationCommandInvokesHandlerOnce() {
        let recorder = InvocationRecorder()
        let action = MenuBarAction(
            runManualCleanup: {},
            restartApplication: {
                recorder.record()
            }
        )

        action.restartApplicationSelected()

        #expect(recorder.invocationCount == 1)
    }
}

private final class InvocationRecorder: @unchecked Sendable {
    private(set) var invocationCount: Int = 0

    func record() {
        invocationCount += 1
    }
}

private final class HotkeySettingsRecorder: @unchecked Sendable {
    var enabledValues: [Bool] = []
    var shortcuts: [KeyboardShortcuts.Shortcut?] = []
}
