import Testing
@testable import ClipPolishCore

private enum MockClipboardError: Error {
    case readFailed
    case writeFailed
}

@MainActor
struct CleanupServiceTests {
    @Test
    func nonTextPayloadReturnsNoPlainTextWithoutReadOrWrite() {
        let gateway = MockClipboardGateway(
            payloadType: .nonText,
            readResult: .success("ignored")
        )
        let service = CleanupService(gateway: gateway, sanitizer: TextSanitizer())

        let result = service.cleanCurrentClipboardText()

        #expect(result == .noPlainText)
        #expect(gateway.readCallCount == 0)
        #expect(gateway.writeCallCount == 0)
    }

    @Test
    func unchangedTextReturnsAlreadyCleanWithoutWrite() {
        let gateway = MockClipboardGateway(
            payloadType: .plainText,
            readResult: .success("Already clean")
        )
        let service = CleanupService(gateway: gateway, sanitizer: TextSanitizer())

        let result = service.cleanCurrentClipboardText()

        #expect(result == .alreadyClean)
        #expect(gateway.readCallCount == 1)
        #expect(gateway.writeCallCount == 0)
    }

    @Test
    func changedTextWritesOnceAndReturnsCleanedSummary() {
        let gateway = MockClipboardGateway(
            payloadType: .plainText,
            readResult: .success(" \u{200B}Hello \n")
        )
        let service = CleanupService(gateway: gateway, sanitizer: TextSanitizer())

        let result = service.cleanCurrentClipboardText()

        if case let .cleaned(summary) = result {
            #expect(summary.totalCharactersRemoved == 4)
        } else {
            Issue.record("Expected cleaned result with summary metadata")
        }

        #expect(gateway.writeCallCount == 1)
        #expect(gateway.lastWrittenText == "Hello")
        #expect(gateway.lastExpectedCurrentText == " \u{200B}Hello \n")
    }

    @Test
    func writeFailureReturnsClipboardWriteFailed() {
        let gateway = MockClipboardGateway(
            payloadType: .plainText,
            readResult: .success(" \u{200B}Hello \n"),
            writeResult: .failure(MockClipboardError.writeFailed)
        )
        let service = CleanupService(gateway: gateway, sanitizer: TextSanitizer())

        let result = service.cleanCurrentClipboardText()

        #expect(result == .clipboardWriteFailed)
        #expect(gateway.writeCallCount == 1)
    }
}

private final class MockClipboardGateway: ClipboardGateway, @unchecked Sendable {
    let payloadType: ClipboardPayloadType
    let readResult: Result<String, Error>
    let writeResult: Result<Void, Error>

    private(set) var readCallCount: Int = 0
    private(set) var writeCallCount: Int = 0
    private(set) var lastWrittenText: String?
    private(set) var lastExpectedCurrentText: String?

    init(
        payloadType: ClipboardPayloadType,
        readResult: Result<String, Error>,
        writeResult: Result<Void, Error> = .success(())
    ) {
        self.payloadType = payloadType
        self.readResult = readResult
        self.writeResult = writeResult
    }

    func currentPayloadType() -> ClipboardPayloadType {
        payloadType
    }

    func readPlainText() throws -> String {
        readCallCount += 1
        return try readResult.get()
    }

    func writePlainText(_ text: String, onlyIfCurrentMatches expectedCurrentText: String) throws {
        writeCallCount += 1
        lastWrittenText = text
        lastExpectedCurrentText = expectedCurrentText
        _ = try writeResult.get()
    }
}
