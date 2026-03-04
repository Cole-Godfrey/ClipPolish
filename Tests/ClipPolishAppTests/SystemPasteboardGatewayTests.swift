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

    @Test
    func plainTextOnlyPayloadCanStillSanitize() {
        let pasteboard = makePasteboard()
        seedPlainTextPayload(
            " \u{200B}Hello \n",
            on: pasteboard
        )
        let gateway = SystemPasteboardGateway(pasteboard: pasteboard)
        let cleanupService = CleanupService(gateway: gateway, sanitizer: TextSanitizer())

        #expect(gateway.currentPayloadType() == .plainText)

        let result = cleanupService.cleanCurrentClipboardText()

        switch result {
        case .cleaned(let summary):
            #expect(summary.scalarsRemoved == 1)
            #expect(summary.leadingCharactersTrimmed == 1)
            #expect(summary.trailingCharactersTrimmed == 2)
        default:
            Issue.record("Expected plain text payload to be sanitized")
        }
        #expect(pasteboard.string(forType: .string) == "Hello")
    }

    @Test
    func opaqueSidecarPayloadStillClassifiesAsPlainText() {
        let pasteboard = makePasteboard()
        seedOpaqueSidecarPayload(
            " \u{200B}Hello \n",
            on: pasteboard
        )
        let gateway = SystemPasteboardGateway(pasteboard: pasteboard)
        let cleanupService = CleanupService(gateway: gateway, sanitizer: TextSanitizer())

        #expect(gateway.currentPayloadType() == .plainText)

        let result = cleanupService.cleanCurrentClipboardText()

        switch result {
        case .cleaned(let summary):
            #expect(summary.scalarsRemoved == 1)
            #expect(summary.leadingCharactersTrimmed == 1)
            #expect(summary.trailingCharactersTrimmed == 2)
        default:
            Issue.record("Expected opaque-sidecar text payload to be sanitized")
        }
        #expect(pasteboard.string(forType: .string) == "Hello")
    }

    @Test
    func imageSidecarPayloadIsClassifiedAsNonText() {
        let pasteboard = makePasteboard()
        seedImageSidecarPayload(
            " \u{200B}Hello \n",
            on: pasteboard
        )
        let gateway = SystemPasteboardGateway(pasteboard: pasteboard)

        #expect(gateway.currentPayloadType() == .nonText)
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

    private func seedPlainTextPayload(_ text: String, on pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        #expect(pasteboard.setString(text, forType: .string))
    }

    private func seedOpaqueSidecarPayload(_ text: String, on pasteboard: NSPasteboard) {
        pasteboard.clearContents()

        let item = NSPasteboardItem()
        #expect(item.setString(text, forType: .string))
        #expect(
            item.setData(
                Data("opaque-sidecar".utf8),
                forType: NSPasteboard.PasteboardType("com.clippolish.tests.opaque-sidecar")
            )
        )
        #expect(pasteboard.writeObjects([item]))
    }

    private func seedImageSidecarPayload(_ text: String, on pasteboard: NSPasteboard) {
        pasteboard.clearContents()

        let item = NSPasteboardItem()
        #expect(item.setString(text, forType: .string))
        #expect(item.setData(Data([0x00, 0x11, 0x22]), forType: .png))
        #expect(pasteboard.writeObjects([item]))
    }

}
