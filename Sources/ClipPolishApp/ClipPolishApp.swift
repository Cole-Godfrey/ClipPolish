import ClipPolishCore
import SwiftUI

@main
struct ClipPolishApp: App {
    @StateObject private var statusPresenter: StatusPresenter
    private let menuActionCoordinator: MenuActionCoordinator

    init() {
        let presenter = StatusPresenter()
        _statusPresenter = StateObject(wrappedValue: presenter)

        let cleanupService = CleanupService(gateway: SystemPasteboardGateway())
        menuActionCoordinator = MenuActionCoordinator(
            cleanupService: cleanupService,
            statusPresenter: presenter
        )
    }

    var body: some Scene {
        MenuBarScene(
            statusPresenter: statusPresenter,
            onCleanClipboardText: { menuActionCoordinator.runManualCleanup() }
        )
    }
}
