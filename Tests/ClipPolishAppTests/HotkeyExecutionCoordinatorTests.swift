import ClipPolishCore
import Foundation
import Testing
@testable import ClipPolishApp

@MainActor
struct HotkeyExecutionCoordinatorTests {
    @Test
    func disabledStateSkipsPermissionCleanupAndPasteWork() async {
        let eventLog = SharedExecutionEventLog()
        let cleanupService = StubCleanupService(result: .alreadyClean, eventLog: eventLog)
        let permissionService = StubAutomationPermissionService(
            preflightResult: true,
            requestResult: true,
            eventLog: eventLog
        )
        let pastePoster = SpyPasteEventPoster(eventLog: eventLog)
        let statusPresenter = SpyStatusPresenter(eventLog: eventLog)
        let coordinator = HotkeyExecutionCoordinator(
            cleanupService: cleanupService,
            permissionService: permissionService,
            pastePoster: pastePoster,
            statusPresenter: statusPresenter,
            isHotkeyEnabledProvider: {
                eventLog.events.append(.enabledCheck(false))
                return false
            },
            frontmostApplicationPIDProvider: {
                eventLog.events.append(.capturedPID(919))
                return 919
            }
        )

        coordinator.runHotkeyCleanAndPaste()
        await drainMainActorQueue()

        #expect(cleanupService.callCount == 0)
        #expect(permissionService.requestCallCount == 0)
        #expect(pastePoster.postedPIDs.isEmpty)
        #expect(statusPresenter.messages.isEmpty)
        #expect(eventLog.events == [.enabledCheck(false)])
    }

    @Test
    func enabledStateStillRunsExistingPermissionAndCleanupFlow() async {
        let eventLog = SharedExecutionEventLog()
        let cleanupService = StubCleanupService(result: .alreadyClean, eventLog: eventLog)
        let permissionService = StubAutomationPermissionService(
            preflightResult: true,
            requestResult: false,
            eventLog: eventLog
        )
        let pastePoster = SpyPasteEventPoster(eventLog: eventLog)
        let statusPresenter = SpyStatusPresenter(eventLog: eventLog)
        let coordinator = HotkeyExecutionCoordinator(
            cleanupService: cleanupService,
            permissionService: permissionService,
            pastePoster: pastePoster,
            statusPresenter: statusPresenter,
            isHotkeyEnabledProvider: {
                eventLog.events.append(.enabledCheck(true))
                return true
            },
            frontmostApplicationPIDProvider: {
                eventLog.events.append(.capturedPID(707))
                return 707
            }
        )

        coordinator.runHotkeyCleanAndPaste()
        await drainMainActorQueue()

        #expect(cleanupService.callCount == 1)
        #expect(permissionService.requestCallCount == 0)
        #expect(pastePoster.postedPIDs == [707])
        #expect(statusPresenter.messages == [.alreadyClean])
        #expect(
            eventLog.events
                == [
                    .enabledCheck(true),
                    .capturedPID(707),
                    .preflightPermission,
                    .cleanup,
                    .paste(targetPID: 707),
                    .status(.alreadyClean)
                ]
        )
    }

    @Test
    func permissionUnavailableRequestsAccessThenShortCircuitsWhenStillDenied() async {
        let eventLog = SharedExecutionEventLog()
        let cleanupService = StubCleanupService(result: .alreadyClean, eventLog: eventLog)
        let permissionService = StubAutomationPermissionService(
            preflightResult: false,
            requestResult: false,
            eventLog: eventLog
        )
        let pastePoster = SpyPasteEventPoster(eventLog: eventLog)
        let statusPresenter = SpyStatusPresenter(eventLog: eventLog)
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
        #expect(permissionService.requestCallCount == 1)
        #expect(
            eventLog.events
                == [
                    .capturedPID(101),
                    .preflightPermission,
                    .requestPermission,
                    .status(.automationPermissionRequired)
                ]
        )
    }

    @Test
    func permissionRequestGrantedOnHotkeyPathRunsCleanupAndPaste() async {
        let eventLog = SharedExecutionEventLog()
        let cleanupService = StubCleanupService(
            result: .cleaned(.init(scalarsRemoved: 1, leadingCharactersTrimmed: 0, trailingCharactersTrimmed: 1)),
            eventLog: eventLog
        )
        let permissionService = StubAutomationPermissionService(
            preflightResult: false,
            requestResult: true,
            eventLog: eventLog
        )
        let pastePoster = SpyPasteEventPoster(eventLog: eventLog)
        let statusPresenter = SpyStatusPresenter(eventLog: eventLog)
        let coordinator = HotkeyExecutionCoordinator(
            cleanupService: cleanupService,
            permissionService: permissionService,
            pastePoster: pastePoster,
            statusPresenter: statusPresenter,
            frontmostApplicationPIDProvider: {
                eventLog.events.append(.capturedPID(202))
                return 202
            }
        )

        coordinator.runHotkeyCleanAndPaste()
        await drainMainActorQueue()

        #expect(cleanupService.callCount == 1)
        #expect(pastePoster.postedPIDs == [202])
        #expect(statusPresenter.messages == [.cleaned(totalCharactersRemoved: 2)])
        #expect(permissionService.requestCallCount == 1)
        #expect(
            eventLog.events
                == [
                    .capturedPID(202),
                    .preflightPermission,
                    .requestPermission,
                    .cleanup,
                    .paste(targetPID: 202),
                    .status(.cleaned(totalCharactersRemoved: 2))
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
        let permissionService = StubAutomationPermissionService(
            preflightResult: true,
            requestResult: false,
            eventLog: eventLog
        )
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
        let permissionService = StubAutomationPermissionService(
            preflightResult: true,
            requestResult: false,
            eventLog: eventLog
        )
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
        let permissionService = StubAutomationPermissionService(
            preflightResult: true,
            requestResult: false,
            eventLog: eventLog
        )
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
    private let requestResult: Bool
    private let eventLog: SharedExecutionEventLog
    private(set) var requestCallCount: Int = 0

    init(preflightResult: Bool, requestResult: Bool, eventLog: SharedExecutionEventLog) {
        self.preflightResult = preflightResult
        self.requestResult = requestResult
        self.eventLog = eventLog
    }

    func preflightPostEventAccess() -> Bool {
        eventLog.events.append(.preflightPermission)
        return preflightResult
    }

    func requestPostEventAccess() -> Bool {
        requestCallCount += 1
        eventLog.events.append(.requestPermission)
        return requestResult
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
        case enabledCheck(Bool)
        case capturedPID(pid_t)
        case preflightPermission
        case requestPermission
        case cleanup
        case paste(targetPID: pid_t?)
        case status(StatusMessage)
    }

    var events: [Event] = []
}
