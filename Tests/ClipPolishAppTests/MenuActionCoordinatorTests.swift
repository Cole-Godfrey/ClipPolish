import ClipPolishCore
import Testing
@testable import ClipPolishApp

private enum MockClipboardError: Error {
    case readFailed
    case writeFailed
}

@MainActor
struct MenuActionCoordinatorTests {
    @Test
    func manualCleanupDelegatesToServiceOncePerClick() {
        let cleanupService = StubCleanupService(result: .alreadyClean)
        let presenter = SpyStatusPresenter()
        let coordinator = MenuActionCoordinator(
            cleanupService: cleanupService,
            statusPresenter: presenter
        )

        coordinator.runManualCleanup()

        #expect(cleanupService.callCount == 1)
        #expect(presenter.messages == [.alreadyClean])
    }

    @Test
    func repeatedInvocationsMatchClickCountWithoutExtraRuns() {
        let cleanupService = StubCleanupService(result: .alreadyClean)
        let presenter = SpyStatusPresenter()
        let coordinator = MenuActionCoordinator(
            cleanupService: cleanupService,
            statusPresenter: presenter
        )

        coordinator.runManualCleanup()
        coordinator.runManualCleanup()
        coordinator.runManualCleanup()

        #expect(cleanupService.callCount == 3)
        #expect(presenter.messages.count == 3)
    }

    @Test
    func nonTextPayloadShowsNoPlainTextWithoutWrite() {
        let gateway = MockClipboardGateway(
            payloadType: .nonText,
            readResult: .success("ignored")
        )
        let cleanupService = CleanupService(gateway: gateway, sanitizer: TextSanitizer())
        let presenter = SpyStatusPresenter()
        let coordinator = MenuActionCoordinator(
            cleanupService: cleanupService,
            statusPresenter: presenter
        )

        coordinator.runManualCleanup()

        #expect(gateway.writeCallCount == 0)
        #expect(presenter.messages.last == .noPlainText)
    }

    @Test
    func alreadyCleanTextShowsAlreadyCleanWithoutWrite() {
        let gateway = MockClipboardGateway(
            payloadType: .plainText,
            readResult: .success("Already clean")
        )
        let cleanupService = CleanupService(gateway: gateway, sanitizer: TextSanitizer())
        let presenter = SpyStatusPresenter()
        let coordinator = MenuActionCoordinator(
            cleanupService: cleanupService,
            statusPresenter: presenter
        )

        coordinator.runManualCleanup()

        #expect(gateway.writeCallCount == 0)
        #expect(presenter.messages.last == .alreadyClean)
    }

    @Test
    func changedTextShowsSuccessSummaryMetadata() {
        let gateway = MockClipboardGateway(
            payloadType: .plainText,
            readResult: .success(" \u{200B}Hello \n")
        )
        let cleanupService = CleanupService(gateway: gateway, sanitizer: TextSanitizer())
        let presenter = SpyStatusPresenter()
        let coordinator = MenuActionCoordinator(
            cleanupService: cleanupService,
            statusPresenter: presenter
        )

        coordinator.runManualCleanup()

        #expect(gateway.writeCallCount == 1)
        #expect(presenter.messages.last == .cleaned(totalCharactersRemoved: 4))
    }

    @Test
    func readFailureShowsReadErrorWithoutWrite() {
        let gateway = MockClipboardGateway(
            payloadType: .plainText,
            readResult: .failure(MockClipboardError.readFailed)
        )
        let cleanupService = CleanupService(gateway: gateway, sanitizer: TextSanitizer())
        let presenter = SpyStatusPresenter()
        let coordinator = MenuActionCoordinator(
            cleanupService: cleanupService,
            statusPresenter: presenter
        )

        coordinator.runManualCleanup()

        #expect(gateway.writeCallCount == 0)
        #expect(presenter.messages.last == .clipboardReadFailed)
    }

    @Test
    func writeFailureShowsWriteError() {
        let gateway = MockClipboardGateway(
            payloadType: .plainText,
            readResult: .success(" \u{200B}Hello \n"),
            writeResult: .failure(MockClipboardError.writeFailed)
        )
        let cleanupService = CleanupService(gateway: gateway, sanitizer: TextSanitizer())
        let presenter = SpyStatusPresenter()
        let coordinator = MenuActionCoordinator(
            cleanupService: cleanupService,
            statusPresenter: presenter
        )

        coordinator.runManualCleanup()

        #expect(gateway.writeCallCount == 1)
        #expect(presenter.messages.last == .clipboardWriteFailed)
    }
}

@MainActor
private final class SpyStatusPresenter: StatusMessagePresenting {
    private(set) var messages: [StatusMessage] = []

    func show(_ message: StatusMessage) {
        messages.append(message)
    }
}

private final class StubCleanupService: ClipboardCleanupServing, @unchecked Sendable {
    let result: CleanupResult
    private(set) var callCount: Int = 0

    init(result: CleanupResult) {
        self.result = result
    }

    func cleanCurrentClipboardText() -> CleanupResult {
        callCount += 1
        return result
    }
}

private final class MockClipboardGateway: ClipboardGateway, @unchecked Sendable {
    let payloadType: ClipboardPayloadType
    let readResult: Result<String, Error>
    let writeResult: Result<Void, Error>

    private(set) var writeCallCount: Int = 0

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
        try readResult.get()
    }

    func writePlainText(_ text: String, onlyIfCurrentMatches expectedCurrentText: String) throws {
        writeCallCount += 1
        _ = try writeResult.get()
    }
}
