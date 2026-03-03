import ClipPolishCore
import Foundation
import Testing
@testable import ClipPolishApp

@MainActor
struct HotkeyExecutionCoordinatorTests {
    @Test
    func permissionUnavailableShortCircuitsBeforeCleanupAndPaste() async {
        let eventLog = SharedExecutionEventLog()
        let cleanupService = StubCleanupService(result: .alreadyClean, eventLog: eventLog)
        let permissionService = StubAutomationPermissionService(preflightResult: false, eventLog: eventLog)
        let pastePoster = SpyPasteEventPoster(eventLog: eventLog)
        let statusPresenter = SpyStatusPresenter()
        let coordinator = HotkeyExecutionCoordinator(
            cleanupService: cleanupService,
            permissionService: permissionService,
            pastePoster: pastePoster,
            statusPresenter: statusPresenter,
            frontmostApplicationPIDProvider: {
                eventLog.events.append(.capturedPID(101))
                return 101
            }
        )

        coordinator.runHotkeyCleanAndPaste()
        await drainMainActorQueue()

        #expect(cleanupService.callCount == 0)
        #expect(pastePoster.postedPIDs.isEmpty)
        #expect(statusPresenter.messages == [.automationPermissionRequired])
        #expect(
            eventLog.events
                == [
                    .capturedPID(101),
                    .preflightPermission,
                    .status(.automationPermissionRequired)
                ]
        )
    }

    @Test
    func permissionAvailablePathRunsCleanupBeforePasteExactlyOnce() async {
        let eventLog = SharedExecutionEventLog()
        let cleanupService = StubCleanupService(
            result: .cleaned(.init(scalarsRemoved: 1, leadingCharactersTrimmed: 1, trailingCharactersTrimmed: 0)),
            eventLog: eventLog
        )
        let permissionService = StubAutomationPermissionService(preflightResult: true, eventLog: eventLog)
        let pastePoster = SpyPasteEventPoster(eventLog: eventLog)
        let statusPresenter = SpyStatusPresenter(eventLog: eventLog)
        let coordinator = HotkeyExecutionCoordinator(
            cleanupService: cleanupService,
            permissionService: permissionService,
            pastePoster: pastePoster,
            statusPresenter: statusPresenter,
            frontmostApplicationPIDProvider: {
                eventLog.events.append(.capturedPID(404))
                return 404
            }
        )

        coordinator.runHotkeyCleanAndPaste()
        await drainMainActorQueue()

        #expect(cleanupService.callCount == 1)
        #expect(pastePoster.postedPIDs == [404])
        #expect(statusPresenter.messages == [.cleaned(totalCharactersRemoved: 2)])
        #expect(
            eventLog.events
                == [
                    .capturedPID(404),
                    .preflightPermission,
                    .cleanup,
                    .paste(targetPID: 404),
                    .status(.cleaned(totalCharactersRemoved: 2))
                ]
        )
    }

    @Test
    func reentrantInvocationsDuringActiveExecutionAreDropped() async {
        let eventLog = SharedExecutionEventLog()
        let cleanupService = StubCleanupService(result: .alreadyClean, eventLog: eventLog)
        let permissionService = StubAutomationPermissionService(preflightResult: true, eventLog: eventLog)
        let pastePoster = SpyPasteEventPoster(eventLog: eventLog)
        let statusPresenter = SpyStatusPresenter()
        let coordinator = HotkeyExecutionCoordinator(
            cleanupService: cleanupService,
            permissionService: permissionService,
            pastePoster: pastePoster,
            statusPresenter: statusPresenter,
            frontmostApplicationPIDProvider: { 5150 }
        )

        coordinator.runHotkeyCleanAndPaste()
        coordinator.runHotkeyCleanAndPaste()
        await drainMainActorQueue()

        #expect(cleanupService.callCount == 1)
        #expect(pastePoster.postedPIDs == [5150])
        #expect(statusPresenter.messages == [.alreadyClean])
    }

    @Test
    func noPlainTextCleanupResultStillPresentsStatusWithoutPasting() async {
        let eventLog = SharedExecutionEventLog()
        let cleanupService = StubCleanupService(result: .noPlainText, eventLog: eventLog)
        let permissionService = StubAutomationPermissionService(preflightResult: true, eventLog: eventLog)
        let pastePoster = SpyPasteEventPoster(eventLog: eventLog)
        let statusPresenter = SpyStatusPresenter()
        let coordinator = HotkeyExecutionCoordinator(
            cleanupService: cleanupService,
            permissionService: permissionService,
            pastePoster: pastePoster,
            statusPresenter: statusPresenter,
            frontmostApplicationPIDProvider: { 808 }
        )

        coordinator.runHotkeyCleanAndPaste()
        await drainMainActorQueue()

        #expect(cleanupService.callCount == 1)
        #expect(pastePoster.postedPIDs.isEmpty)
        #expect(statusPresenter.messages == [.noPlainText])
    }

    private func drainMainActorQueue() async {
        await Task.yield()
        await Task.yield()
        await Task.yield()
    }
}

private final class StubCleanupService: ClipboardCleanupServing, @unchecked Sendable {
    private let result: CleanupResult
    private let eventLog: SharedExecutionEventLog
    private(set) var callCount: Int = 0

    init(result: CleanupResult, eventLog: SharedExecutionEventLog) {
        self.result = result
        self.eventLog = eventLog
    }

    func cleanCurrentClipboardText() -> CleanupResult {
        callCount += 1
        eventLog.events.append(.cleanup)
        return result
    }
}

private final class StubAutomationPermissionService: AutomationPermissionServing, @unchecked Sendable {
    private let preflightResult: Bool
    private let eventLog: SharedExecutionEventLog

    init(preflightResult: Bool, eventLog: SharedExecutionEventLog) {
        self.preflightResult = preflightResult
        self.eventLog = eventLog
    }

    func preflightPostEventAccess() -> Bool {
        eventLog.events.append(.preflightPermission)
        return preflightResult
    }
}

private final class SpyPasteEventPoster: PasteEventPosting, @unchecked Sendable {
    private(set) var postedPIDs: [pid_t?] = []
    private let eventLog: SharedExecutionEventLog

    init(eventLog: SharedExecutionEventLog) {
        self.eventLog = eventLog
    }

    func postPaste(targetPID: pid_t?) {
        postedPIDs.append(targetPID)
        eventLog.events.append(.paste(targetPID: targetPID))
    }
}

@MainActor
private final class SpyStatusPresenter: StatusMessagePresenting {
    private(set) var messages: [StatusMessage] = []
    private let eventLog: SharedExecutionEventLog?

    init(eventLog: SharedExecutionEventLog? = nil) {
        self.eventLog = eventLog
    }

    func show(_ message: StatusMessage) {
        messages.append(message)
        eventLog?.events.append(.status(message))
    }
}

private final class SharedExecutionEventLog: @unchecked Sendable {
    enum Event: Equatable {
        case capturedPID(pid_t)
        case preflightPermission
        case cleanup
        case paste(targetPID: pid_t?)
        case status(StatusMessage)
    }

    var events: [Event] = []
}
