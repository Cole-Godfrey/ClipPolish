import Carbon.HIToolbox
import CoreGraphics
import Foundation

@MainActor
protocol PasteEventPosting: Sendable {
    func postPaste(targetPID: pid_t?)
}

struct CoreGraphicsPasteEventPoster: PasteEventPosting {
    func postPaste(targetPID: pid_t?) {
        guard
            let keyDown = makePasteEvent(keyDown: true),
            let keyUp = makePasteEvent(keyDown: false)
        else {
            return
        }

        if let targetPID {
            keyDown.postToPid(targetPID)
            keyUp.postToPid(targetPID)
            return
        }

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }

    private func makePasteEvent(keyDown: Bool) -> CGEvent? {
        guard let event = CGEvent(
            keyboardEventSource: CGEventSource(stateID: .combinedSessionState),
            virtualKey: CGKeyCode(kVK_ANSI_V),
            keyDown: keyDown
        ) else {
            return nil
        }

        event.flags = .maskCommand
        return event
    }
}
