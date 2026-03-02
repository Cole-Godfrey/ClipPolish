import AppKit
import SwiftUI

struct MenuBarAction {
    private let runManualCleanup: () -> Void

    init(runManualCleanup: @escaping () -> Void) {
        self.runManualCleanup = runManualCleanup
    }

    func cleanClipboardTextSelected() {
        runManualCleanup()
    }
}

struct MenuBarScene: Scene {
    @ObservedObject var statusPresenter: StatusPresenter
    let menuBarAction: MenuBarAction

    init(statusPresenter: StatusPresenter, onCleanClipboardText: @escaping () -> Void) {
        self.statusPresenter = statusPresenter
        self.menuBarAction = MenuBarAction(runManualCleanup: onCleanClipboardText)
    }

    var body: some Scene {
        MenuBarExtra("ClipPolish", systemImage: "sparkles") {
            if let message = statusPresenter.currentMessage {
                Text(message.displayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Divider()
            }

            Button("Clean Clipboard Text", action: menuBarAction.cleanClipboardTextSelected)
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
