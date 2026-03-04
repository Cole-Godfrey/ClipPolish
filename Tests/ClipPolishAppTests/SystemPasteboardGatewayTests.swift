import AppKit
import ClipPolishCore
import Testing
@testable import ClipPolishApp

@MainActor
struct SystemPasteboardGatewayTests {
    @Test
    func mixedRepresentationPayloadIsClassifiedAsNonText() {
        let pasteboard = makePasteboard()
        seedMixedTextPayload(
            " \u{200B}Hello \n",
            on: pasteboard
        )
        let gateway = SystemPasteboardGateway(pasteboard: pasteboard)

        #expect(gateway.currentPayloadType() == .nonText)
    }

    @Test
    func cleanupServiceNoOpsMixedRepresentationPayloadWithoutMutation() {
        let pasteboard = makePasteboard()
        seedMixedTextPayload(
            " \u{200B}Hello \n",
            on: pasteboard
        )
        let gateway = SystemPasteboardGateway(pasteboard: pasteboard)
        let cleanupService = CleanupService(gateway: gateway, sanitizer: TextSanitizer())
        let before = snapshot(of: pasteboard)

        let result = cleanupService.cleanCurrentClipboardText()

        #expect(result == .noPlainText)
        #expect(snapshot(of: pasteboard) == before)
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

    private func snapshot(of pasteboard: NSPasteboard) -> [PasteboardItemSnapshot] {
        (pasteboard.pasteboardItems ?? []).map { item in
            PasteboardItemSnapshot(
                representations: item.types.map { type in
                    PasteboardRepresentationSnapshot(
                        type: type.rawValue,
                        bytes: item.data(forType: type) ?? Data()
                    )
                }
                .sorted(by: { lhs, rhs in lhs.type < rhs.type })
            )
        }
    }
}

private struct PasteboardItemSnapshot: Equatable {
    let representations: [PasteboardRepresentationSnapshot]
}

private struct PasteboardRepresentationSnapshot: Equatable {
    let type: String
    let bytes: Data
}
