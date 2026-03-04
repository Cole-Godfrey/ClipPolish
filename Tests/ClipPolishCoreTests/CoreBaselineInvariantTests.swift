import Testing
@testable import ClipPolishCore

@MainActor
struct CoreBaselineInvariantTests {
    @Test
    func removableScalarListV1MatchesContractExactly() {
        let expected: Set<UnicodeScalar> = [
            UnicodeScalar(0xFEFF)!,
            UnicodeScalar(0x200B)!,
            UnicodeScalar(0x2060)!,
            UnicodeScalar(0x00AD)!
        ]

        #expect(RemovableScalarList.v1 == expected)
        #expect(RemovableScalarList.v1.count == 4)
    }

    @Test
    func payloadClassifierTreatsOnlyPlainTextAsCleanable() {
        let classifier = ClipboardPayloadClassifier()

        #expect(classifier.classify(.plainText) == .plainText)
        #expect(classifier.classify(.nonText) == .noPlainText)
    }

    @Test
    func cleanupServiceReturnsNoPlainTextWithoutClipboardReadOrWrite() {
        let gateway = NonTextContractGateway()
        let service = CleanupService(gateway: gateway)

        let result = service.cleanCurrentClipboardText()

        #expect(result == .noPlainText)
        #expect(gateway.readCallCount == 0)
        #expect(gateway.writeCallCount == 0)
    }
}

private final class NonTextContractGateway: ClipboardGateway, @unchecked Sendable {
    private(set) var readCallCount = 0
    private(set) var writeCallCount = 0

    func currentPayloadType() -> ClipboardPayloadType {
        .nonText
    }

    func readPlainText() throws -> String {
        readCallCount += 1
        throw BaselineGatewayError.readShouldNotBeCalled
    }

    func writePlainText(_ text: String, onlyIfCurrentMatches expectedCurrentText: String) throws {
        writeCallCount += 1
        throw BaselineGatewayError.writeShouldNotBeCalled
    }
}

private enum BaselineGatewayError: Error {
    case readShouldNotBeCalled
    case writeShouldNotBeCalled
}
