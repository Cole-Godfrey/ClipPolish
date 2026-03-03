import ClipPolishCore
import Foundation
import Testing
@testable import ClipPolishApp

@MainActor
struct HotkeyPermissionGuidanceTests {
    @Test
    func blockedHotkeyShowsPermissionGuidanceWithoutCleanupOrPaste() async {
        let cleanupService = GuidanceStubCleanupService(result: .alreadyClean)
        let permissionService = GuidanceStubAutomationPermissionService(
            preflightResult: false,
            requestResult: false
        )
        let pastePoster = GuidanceSpyPasteEventPoster()
        let statusPresenter = GuidanceSpyStatusPresenter()
        let settingsOpener = GuidanceSpySettingsOpener()
        let coordinator = HotkeyExecutionCoordinator(
            cleanupService: cleanupService,
            permissionService: permissionService,
            pastePoster: pastePoster,
            statusPresenter: statusPresenter,
            accessibilitySettingsOpener: settingsOpener.open,
            frontmostApplicationPIDProvider: { 1337 }
        )

        coordinator.runHotkeyCleanAndPaste()
        await drainMainActorQueue()

        #expect(cleanupService.callCount == 0)
        #expect(permissionService.requestCallCount == 1)
        #expect(pastePoster.postedPIDs.isEmpty)
        #expect(settingsOpener.openCallCount == 0)
        #expect(statusPresenter.messages == [.automationPermissionRequired])
        #expect(
            statusPresenter.messages.last?.permissionGuidance?.settingsPath
                == "System Settings -> Privacy & Security -> Accessibility"
        )
        #expect(
            statusPresenter.messages.last?.permissionGuidance?.actionTitle
                == "Request Accessibility Permission"
        )
        #expect(
            statusPresenter.messages.last?.permissionGuidance?.manualSteps
                == [
                    "Open Accessibility settings.",
                    "Enable ClipPolish in the app list.",
                    "Return to your app and press the hotkey again."
                ]
        )
    }

    @Test
    func permissionRequestActionPublishesDeniedGuidanceWhenRequestFails() async {
        let cleanupService = GuidanceStubCleanupService(result: .alreadyClean)
        let permissionService = GuidanceStubAutomationPermissionService(
            preflightResult: false,
            requestResult: false
        )
        let pastePoster = GuidanceSpyPasteEventPoster()
        let statusPresenter = GuidanceSpyStatusPresenter()
        let settingsOpener = GuidanceSpySettingsOpener()
        let coordinator = HotkeyExecutionCoordinator(
            cleanupService: cleanupService,
            permissionService: permissionService,
            pastePoster: pastePoster,
            statusPresenter: statusPresenter,
            accessibilitySettingsOpener: settingsOpener.open,
            frontmostApplicationPIDProvider: { 10 }
        )

        coordinator.requestAutomationPermissionIfNeeded()
        await drainMainActorQueue()

        #expect(permissionService.requestCallCount == 1)
        #expect(cleanupService.callCount == 0)
        #expect(pastePoster.postedPIDs.isEmpty)
        #expect(settingsOpener.openCallCount == 1)
        #expect(statusPresenter.messages == [.automationPermissionRequestDenied])
    }

    @Test
    func permissionRequestActionPublishesGrantedStatusWhenRequestSucceeds() async {
        let cleanupService = GuidanceStubCleanupService(result: .alreadyClean)
        let permissionService = GuidanceStubAutomationPermissionService(
            preflightResult: false,
            requestResult: true
        )
        let pastePoster = GuidanceSpyPasteEventPoster()
        let statusPresenter = GuidanceSpyStatusPresenter()
        let settingsOpener = GuidanceSpySettingsOpener()
        let coordinator = HotkeyExecutionCoordinator(
            cleanupService: cleanupService,
            permissionService: permissionService,
            pastePoster: pastePoster,
            statusPresenter: statusPresenter,
            accessibilitySettingsOpener: settingsOpener.open,
            frontmostApplicationPIDProvider: { 10 }
        )

        coordinator.requestAutomationPermissionIfNeeded()
        await drainMainActorQueue()

        #expect(permissionService.requestCallCount == 1)
        #expect(cleanupService.callCount == 0)
        #expect(pastePoster.postedPIDs.isEmpty)
        #expect(settingsOpener.openCallCount == 0)
        #expect(statusPresenter.messages == [.automationPermissionGranted])
    }

    @Test
    func deniedPermissionRequestPublishesGuidanceMetadataWithoutClipboardDetails() async {
        let cleanupService = GuidanceStubCleanupService(result: .alreadyClean)
        let permissionService = GuidanceStubAutomationPermissionService(
            preflightResult: false,
            requestResult: false
        )
        let pastePoster = GuidanceSpyPasteEventPoster()
        let statusPresenter = GuidanceSpyStatusPresenter()
        let settingsOpener = GuidanceSpySettingsOpener()
        let coordinator = HotkeyExecutionCoordinator(
            cleanupService: cleanupService,
            permissionService: permissionService,
            pastePoster: pastePoster,
            statusPresenter: statusPresenter,
            accessibilitySettingsOpener: settingsOpener.open,
            frontmostApplicationPIDProvider: { 5 }
        )

        coordinator.requestAutomationPermissionIfNeeded()
        await drainMainActorQueue()

        #expect(cleanupService.callCount == 0)
        #expect(pastePoster.postedPIDs.isEmpty)
        #expect(settingsOpener.openCallCount == 1)
        #expect(
            statusPresenter.messages.last?.permissionGuidance?.settingsPath
                == "System Settings -> Privacy & Security -> Accessibility"
        )
        #expect(statusPresenter.messages.last?.displayText.contains("clipboard") == false)
    }

    private func drainMainActorQueue() async {
        await Task.yield()
        await Task.yield()
        await Task.yield()
    }
}

private final class GuidanceStubCleanupService: ClipboardCleanupServing, @unchecked Sendable {
    private let result: CleanupResult
    private(set) var callCount: Int = 0

    init(result: CleanupResult) {
        self.result = result
    }

    func cleanCurrentClipboardText() -> CleanupResult {
        callCount += 1
        return result
    }
}

private final class GuidanceStubAutomationPermissionService: AutomationPermissionServing, @unchecked Sendable {
    private let preflightResult: Bool
    private let requestResult: Bool

    private(set) var preflightCallCount: Int = 0
    private(set) var requestCallCount: Int = 0

    init(preflightResult: Bool, requestResult: Bool) {
        self.preflightResult = preflightResult
        self.requestResult = requestResult
    }

    func preflightPostEventAccess() -> Bool {
        preflightCallCount += 1
        return preflightResult
    }

    func requestPostEventAccess() -> Bool {
        requestCallCount += 1
        return requestResult
    }
}

private final class GuidanceSpyPasteEventPoster: PasteEventPosting, @unchecked Sendable {
    private(set) var postedPIDs: [pid_t?] = []

    func postPaste(targetPID: pid_t?) {
        postedPIDs.append(targetPID)
    }
}

@MainActor
private final class GuidanceSpySettingsOpener {
    private(set) var openCallCount: Int = 0

    func open() {
        openCallCount += 1
    }
}

@MainActor
private final class GuidanceSpyStatusPresenter: StatusMessagePresenting {
    private(set) var messages: [StatusMessage] = []

    func show(_ message: StatusMessage) {
        messages.append(message)
    }
}
