import ClipPolishCore
import Testing
@testable import ClipPolishApp

@MainActor
struct ManualCleanupFlowTests {
    @Test
    func nonTextClipboardLeavesSnapshotUnchangedAndShowsNoPlainText() {
        let gateway = TrackingClipboardGateway(
            payloadType: .nonText,
            plainTextSnapshot: "Pretend plain text fallback"
        )
        let cleanupService = CleanupService(gateway: gateway, sanitizer: TextSanitizer())
        let presenter = SpyStatusPresenter()
        let coordinator = MenuActionCoordinator(
            cleanupService: cleanupService,
            statusPresenter: presenter
        )
        let before = gateway.snapshot

        coordinator.runManualCleanup()

        #expect(gateway.readCallCount == 0)
        #expect(gateway.writeCallCount == 0)
        #expect(gateway.snapshot == before)
        #expect(presenter.messages.last == .noPlainText)
    }

    @Test
    func mixedRepresentationNonTextPathStillStaysNoOp() {
        let gateway = TrackingClipboardGateway(
            payloadType: .nonText,
            plainTextSnapshot: " \u{200B}Mixed content that should remain untouched \n"
        )
        let cleanupService = CleanupService(gateway: gateway, sanitizer: TextSanitizer())
        let presenter = SpyStatusPresenter()
        let coordinator = MenuActionCoordinator(
            cleanupService: cleanupService,
            statusPresenter: presenter
        )
        let before = gateway.snapshot

        coordinator.runManualCleanup()

        #expect(gateway.readCallCount == 0)
        #expect(gateway.writeCallCount == 0)
        #expect(gateway.snapshot == before)
        #expect(presenter.messages.last == .noPlainText)
    }

    @Test
    func alreadyCleanTextShowsAlreadyCleanWithoutWrite() {
        let gateway = TrackingClipboardGateway(
            payloadType: .plainText,
            plainTextSnapshot: "Already clean"
        )
        let cleanupService = CleanupService(gateway: gateway, sanitizer: TextSanitizer())
        let presenter = SpyStatusPresenter()
        let coordinator = MenuActionCoordinator(
            cleanupService: cleanupService,
            statusPresenter: presenter
        )
        let before = gateway.snapshot

        coordinator.runManualCleanup()

        #expect(gateway.readCallCount == 1)
        #expect(gateway.writeCallCount == 0)
        #expect(gateway.snapshot == before)
        #expect(presenter.messages.last == .alreadyClean)
    }

    @Test
    func changedTextWritesOnceAndPublishesCleanedSummary() {
        let gateway = TrackingClipboardGateway(
            payloadType: .plainText,
            plainTextSnapshot: " \u{200B}Hello \n"
        )
        let cleanupService = CleanupService(gateway: gateway, sanitizer: TextSanitizer())
        let presenter = SpyStatusPresenter()
        let coordinator = MenuActionCoordinator(
            cleanupService: cleanupService,
            statusPresenter: presenter
        )

        coordinator.runManualCleanup()

        #expect(gateway.readCallCount == 1)
        #expect(gateway.writeCallCount == 1)
        #expect(gateway.snapshot.plainText == "Hello")
        #expect(gateway.snapshot.writeHistory == ["Hello"])
        #expect(presenter.messages.last == .cleaned(totalCharactersRemoved: 4))
    }
}

@MainActor
private final class SpyStatusPresenter: StatusMessagePresenting {
    private(set) var messages: [StatusMessage] = []

    func show(_ message: StatusMessage) {
        messages.append(message)
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

        guard plainTextSnapshot == expectedCurrentText else {
            return
        }

        plainTextSnapshot = text
        writeHistory.append(text)
    }
}
