import AppKit
import SwiftUI

struct MenuBarScene: Scene {
    let onCleanClipboardText: () -> Void

    var body: some Scene {
        MenuBarExtra("ClipPolish", systemImage: "sparkles") {
            Button("Clean Clipboard Text", action: onCleanClipboardText)
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
