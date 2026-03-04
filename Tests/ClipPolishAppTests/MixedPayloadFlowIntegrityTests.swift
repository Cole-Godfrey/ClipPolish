import AppKit
import ClipPolishCore
import Testing
@testable import ClipPolishApp

@MainActor
struct MixedPayloadFlowIntegrityTests {
    @Test
    func manualEntryPointSanitizesMixedPayloadAndPublishesCleanedStatus() {
        let pasteboard = makePasteboard()
        seedMixedTextPayload(" \u{200B}Hello \n", on: pasteboard)
        let cleanupService = makeCleanupService(for: pasteboard)
        let statusPresenter = SpyStatusPresenter()
        let coordinator = MenuActionCoordinator(
            cleanupService: cleanupService,
            statusPresenter: statusPresenter
        )

        coordinator.runManualCleanup()

        #expect(pasteboard.string(forType: .string) == "Hello")
        #expect(statusPresenter.messages == [.cleaned(totalCharactersRemoved: 4)])
    }

    @Test
    func hotkeyEntryPointSanitizesMixedPayloadAndPostsPaste() async {
        let pasteboard = makePasteboard()
        seedMixedTextPayload(" \u{200B}Hello \n", on: pasteboard)
        let cleanupService = makeCleanupService(for: pasteboard)
        let permissionService = StubAutomationPermissionService(preflightResult: true, requestResult: false)
        let pastePoster = SpyPasteEventPoster()
        let statusPresenter = SpyStatusPresenter()
        let coordinator = HotkeyExecutionCoordinator(
            cleanupService: cleanupService,
            permissionService: permissionService,
            pastePoster: pastePoster,
            statusPresenter: statusPresenter,
            frontmostApplicationPIDProvider: { 5150 }
        )

        coordinator.runHotkeyCleanAndPaste()
        await drainMainActorQueue()

        #expect(pasteboard.string(forType: .string) == "Hello")
        #expect(permissionService.requestCallCount == 0)
        #expect(pastePoster.postedPIDs == [5150])
        #expect(statusPresenter.messages == [.cleaned(totalCharactersRemoved: 4)])
    }

    @Test
    func manualEntryPointStillSanitizesPlainTextOnlyPayload() {
        let pasteboard = makePasteboard()
        seedPlainTextPayload(" \u{200B}Hello \n", on: pasteboard)
        let cleanupService = makeCleanupService(for: pasteboard)
        let statusPresenter = SpyStatusPresenter()
        let coordinator = MenuActionCoordinator(
            cleanupService: cleanupService,
            statusPresenter: statusPresenter
        )

        coordinator.runManualCleanup()

        #expect(pasteboard.string(forType: .string) == "Hello")
        #expect(statusPresenter.messages == [.cleaned(totalCharactersRemoved: 4)])
    }

    @Test
    func hotkeyEntryPointStillSanitizesPlainTextOnlyPayloadAndPostsPaste() async {
        let pasteboard = makePasteboard()
        seedPlainTextPayload(" \u{200B}Hello \n", on: pasteboard)
        let cleanupService = makeCleanupService(for: pasteboard)
        let permissionService = StubAutomationPermissionService(preflightResult: true, requestResult: false)
        let pastePoster = SpyPasteEventPoster()
        let statusPresenter = SpyStatusPresenter()
        let coordinator = HotkeyExecutionCoordinator(
            cleanupService: cleanupService,
            permissionService: permissionService,
            pastePoster: pastePoster,
            statusPresenter: statusPresenter,
            frontmostApplicationPIDProvider: { 4242 }
        )

        coordinator.runHotkeyCleanAndPaste()
        await drainMainActorQueue()

        #expect(pasteboard.string(forType: .string) == "Hello")
        #expect(permissionService.requestCallCount == 0)
        #expect(pastePoster.postedPIDs == [4242])
        #expect(statusPresenter.messages == [.cleaned(totalCharactersRemoved: 4)])
    }

    private func makePasteboard() -> NSPasteboard {
        NSPasteboard(name: NSPasteboard.Name("clip-polish-flow-\(UUID().uuidString)"))
    }

    private func makeCleanupService(for pasteboard: NSPasteboard) -> CleanupService {
        let gateway = SystemPasteboardGateway(pasteboard: pasteboard)
        return CleanupService(gateway: gateway, sanitizer: TextSanitizer())
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

    private func drainMainActorQueue() async {
        await Task.yield()
        await Task.yield()
        await Task.yield()
    }
}

private final class StubAutomationPermissionService: AutomationPermissionServing, @unchecked Sendable {
    private let preflightResult: Bool
    private let requestResult: Bool
    private(set) var requestCallCount: Int = 0

    init(preflightResult: Bool, requestResult: Bool) {
        self.preflightResult = preflightResult
        self.requestResult = requestResult
    }

    func preflightPostEventAccess() -> Bool {
        preflightResult
    }

    func requestPostEventAccess() -> Bool {
        requestCallCount += 1
        return requestResult
    }
}

private final class SpyPasteEventPoster: PasteEventPosting, @unchecked Sendable {
    private(set) var postedPIDs: [pid_t?] = []

    func postPaste(targetPID: pid_t?) {
        postedPIDs.append(targetPID)
    }
}

@MainActor
private final class SpyStatusPresenter: StatusMessagePresenting {
    private(set) var messages: [StatusMessage] = []

    func show(_ message: StatusMessage) {
        messages.append(message)
    }
}
