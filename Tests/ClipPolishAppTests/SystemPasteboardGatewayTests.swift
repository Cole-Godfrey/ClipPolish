import AppKit
import ClipPolishCore
import Testing
@testable import ClipPolishApp

@MainActor
struct SystemPasteboardGatewayTests {
    @Test
    func mixedRepresentationTextIsClassifiedAsPlainText() {
        let pasteboard = makePasteboard()
        seedMixedTextPayload(
            " \u{200B}Hello \n",
            on: pasteboard
        )
        let gateway = SystemPasteboardGateway(pasteboard: pasteboard)

        #expect(gateway.currentPayloadType() == .plainText)
    }

    @Test
    func cleanupServiceSanitizesMixedRepresentationClipboardText() {
        let pasteboard = makePasteboard()
        seedMixedTextPayload(
            " \u{200B}Hello \n",
            on: pasteboard
        )
        let gateway = SystemPasteboardGateway(pasteboard: pasteboard)
        let cleanupService = CleanupService(gateway: gateway, sanitizer: TextSanitizer())

        let result = cleanupService.cleanCurrentClipboardText()

        switch result {
        case .cleaned(let summary):
            #expect(summary.scalarsRemoved == 1)
            #expect(summary.leadingCharactersTrimmed == 1)
            #expect(summary.trailingCharactersTrimmed == 2)
        default:
            Issue.record("Expected mixed text payload to be sanitized")
        }
        #expect(pasteboard.string(forType: .string) == "Hello")
    }

    private func makePasteboard() -> NSPasteboard {
        NSPasteboard(name: NSPasteboard.Name("clip-polish-tests-\(UUID().uuidString)"))
    }

    private func seedMixedTextPayload(_ text: String, on pasteboard: NSPasteboard) {
        pasteboard.clearContents()

        let item = NSPasteboardItem()
        #expect(item.setString(text, forType: .string))
        #expect(item.setString("{\\\\rtf1\\\\ansi Mixed text payload}", forType: .rtf))
        #expect(pasteboard.writeObjects([item]))
    }
}
