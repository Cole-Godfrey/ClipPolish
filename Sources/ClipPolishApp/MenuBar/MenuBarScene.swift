import AppKit
import SwiftUI

struct MenuBarScene: Scene {
    @ObservedObject var statusPresenter: StatusPresenter
    let onCleanClipboardText: () -> Void

    var body: some Scene {
        MenuBarExtra("ClipPolish", systemImage: "sparkles") {
            if let message = statusPresenter.currentMessage {
                Text(message.displayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Divider()
            }

            Button("Clean Clipboard Text", action: onCleanClipboardText)
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
