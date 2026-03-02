import ClipPolishCore

protocol ClipboardCleanupServing: Sendable {
    func cleanCurrentClipboardText() -> CleanupResult
}

extension CleanupService: ClipboardCleanupServing {}

@MainActor
struct MenuActionCoordinator {
    private let cleanupService: any ClipboardCleanupServing
    private let statusPresenter: any StatusMessagePresenting

    init(
        cleanupService: any ClipboardCleanupServing,
        statusPresenter: any StatusMessagePresenting
    ) {
        self.cleanupService = cleanupService
        self.statusPresenter = statusPresenter
    }

    func runManualCleanup() {
        let result = cleanupService.cleanCurrentClipboardText()
        statusPresenter.show(StatusMessage.fromCleanupResult(result))
    }
}
