import Foundation
import Testing
@testable import ClipPolishApp

@MainActor
struct StatusPresenterTests {
    @Test
    func cleanedMessageAutoDismissesAfterConfiguredDuration() async {
        let presenter = StatusPresenter(displayDurationNanoseconds: 10_000_000)

        presenter.show(.cleaned(totalCharactersRemoved: 2))

        #expect(presenter.currentMessage == .cleaned(totalCharactersRemoved: 2))

        try? await Task.sleep(nanoseconds: 30_000_000)

        #expect(presenter.currentMessage == nil)
    }

    @Test
    func permissionRequiredMessageDoesNotAutoDismiss() async {
        let presenter = StatusPresenter(displayDurationNanoseconds: 10_000_000)

        presenter.show(.automationPermissionRequired)
        try? await Task.sleep(nanoseconds: 30_000_000)

        #expect(presenter.currentMessage == .automationPermissionRequired)
    }

    @Test
    func deniedPermissionMessageDoesNotAutoDismiss() async {
        let presenter = StatusPresenter(displayDurationNanoseconds: 10_000_000)

        presenter.show(.automationPermissionRequestDenied)
        try? await Task.sleep(nanoseconds: 30_000_000)

        #expect(presenter.currentMessage == .automationPermissionRequestDenied)
    }
}
