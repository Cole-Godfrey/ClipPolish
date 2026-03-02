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
}

private final class InvocationRecorder: @unchecked Sendable {
    private(set) var invocationCount: Int = 0

    func record() {
        invocationCount += 1
    }
}
