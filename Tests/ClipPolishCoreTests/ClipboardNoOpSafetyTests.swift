import Testing
@testable import ClipPolishCore

@MainActor
struct ClipboardNoOpSafetyTests {
    @Test
    func nonTextPayloadDoesNotReadOrWriteAndLeavesSnapshotUnchanged() {
        let gateway = TrackingClipboardGateway(
            payloadType: .nonText,
            plainTextSnapshot: "Original snapshot"
        )
        let service = CleanupService(gateway: gateway, sanitizer: TextSanitizer())
        let before = gateway.snapshot

        let result = service.cleanCurrentClipboardText()

        #expect(result == .noPlainText)
        #expect(gateway.readCallCount == 0)
        #expect(gateway.writeCallCount == 0)
        #expect(gateway.snapshot == before)
    }

    @Test
    func mixedRepresentationStillAvoidsMutationWhenPayloadIsNonText() {
        let gateway = TrackingClipboardGateway(
            payloadType: .nonText,
            plainTextSnapshot: " \u{200B}Should Stay Untouched \n"
        )
        let service = CleanupService(gateway: gateway, sanitizer: TextSanitizer())
        let before = gateway.snapshot

        let result = service.cleanCurrentClipboardText()

        #expect(result == .noPlainText)
        #expect(gateway.readCallCount == 0)
        #expect(gateway.writeCallCount == 0)
        #expect(gateway.snapshot == before)
    }

    @Test
    func unchangedTextReadsOnceWithoutWriteAndPreservesSnapshot() {
        let gateway = TrackingClipboardGateway(
            payloadType: .plainText,
            plainTextSnapshot: "Already clean"
        )
        let service = CleanupService(gateway: gateway, sanitizer: TextSanitizer())
        let before = gateway.snapshot

        let result = service.cleanCurrentClipboardText()

        #expect(result == .alreadyClean)
        #expect(gateway.readCallCount == 1)
        #expect(gateway.writeCallCount == 0)
        #expect(gateway.snapshot == before)
    }

    @Test
    func changedTextWritesExactlyOnceWhenOutputDiffers() {
        let gateway = TrackingClipboardGateway(
            payloadType: .plainText,
            plainTextSnapshot: " \u{200B}Hello \n"
        )
        let service = CleanupService(gateway: gateway, sanitizer: TextSanitizer())

        let result = service.cleanCurrentClipboardText()

        if case let .cleaned(summary) = result {
            #expect(summary.totalCharactersRemoved == 4)
        } else {
            Issue.record("Expected cleanup to report a cleaned summary")
        }

        #expect(gateway.readCallCount == 1)
        #expect(gateway.writeCallCount == 1)
        #expect(gateway.lastWrittenText == "Hello")
        #expect(gateway.lastExpectedCurrentText == " \u{200B}Hello \n")
        #expect(gateway.snapshot.plainText == "Hello")
        #expect(gateway.snapshot.writeHistory == ["Hello"])
    }
}

private struct ClipboardSnapshot: Equatable {
    let payloadType: ClipboardPayloadType
    let plainText: String
    let writeHistory: [String]
}

private final class TrackingClipboardGateway: ClipboardGateway, @unchecked Sendable {
    private let payloadType: ClipboardPayloadType
    private(set) var plainTextSnapshot: String

    private(set) var readCallCount: Int = 0
    private(set) var writeCallCount: Int = 0
    private(set) var writeHistory: [String] = []
    private(set) var lastWrittenText: String?
    private(set) var lastExpectedCurrentText: String?

    init(payloadType: ClipboardPayloadType, plainTextSnapshot: String) {
        self.payloadType = payloadType
        self.plainTextSnapshot = plainTextSnapshot
    }

    var snapshot: ClipboardSnapshot {
        ClipboardSnapshot(
            payloadType: payloadType,
            plainText: plainTextSnapshot,
            writeHistory: writeHistory
        )
    }

    func currentPayloadType() -> ClipboardPayloadType {
        payloadType
    }

    func readPlainText() throws -> String {
        readCallCount += 1
        return plainTextSnapshot
    }

    func writePlainText(_ text: String, onlyIfCurrentMatches expectedCurrentText: String) throws {
        writeCallCount += 1
        lastWrittenText = text
        lastExpectedCurrentText = expectedCurrentText

        guard plainTextSnapshot == expectedCurrentText else {
            return
        }

        plainTextSnapshot = text
        writeHistory.append(text)
    }
}
