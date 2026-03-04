import Foundation
import SwiftUI

@MainActor
protocol StatusMessagePresenting: AnyObject {
    func show(_ message: StatusMessage)
}

@MainActor
protocol HotkeySmokeDiagnosticsSinking: AnyObject {
    func record(event: String)
}

@MainActor
final class StatusPresenter: ObservableObject, StatusMessagePresenting {
    @Published private(set) var currentMessage: StatusMessage?
    private var clearTask: Task<Void, Never>?
    private let displayDurationNanoseconds: UInt64
    private let smokeDiagnosticsSink: (any HotkeySmokeDiagnosticsSinking)?

    init(
        displayDurationNanoseconds: UInt64 = 2_000_000_000,
        smokeDiagnosticsSink: (any HotkeySmokeDiagnosticsSinking)? = nil
    ) {
        self.displayDurationNanoseconds = displayDurationNanoseconds
        self.smokeDiagnosticsSink = smokeDiagnosticsSink
    }

    func show(_ message: StatusMessage) {
        smokeDiagnosticsSink?.record(event: "hotkey.status=\(message.smokeToken)")
        currentMessage = message
        clearTask?.cancel()

        guard message.shouldAutoDismiss else {
            return
        }

        clearTask = Task { @MainActor [weak self, displayDurationNanoseconds] in
            try? await Task.sleep(nanoseconds: displayDurationNanoseconds)
            guard let self, !Task.isCancelled else {
                return
            }
            self.currentMessage = nil
        }
    }

    deinit {
        clearTask?.cancel()
    }
}

final class HotkeySmokeDiagnosticsFileSink: HotkeySmokeDiagnosticsSinking {
    private let outputURL: URL
    private let fileManager: FileManager

    init?(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) {
        guard environment["CLIPPOLISH_RUN_HOTKEY_E2E"] == "1" else {
            return nil
        }

        guard let rawPath = environment["CLIPPOLISH_SMOKE_EVENT_LOG_PATH"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !rawPath.isEmpty
        else {
            return nil
        }

        self.outputURL = URL(fileURLWithPath: rawPath)
        self.fileManager = fileManager
    }

    func record(event: String) {
        let payload = Data("\(event)\n".utf8)
        let directoryURL = outputURL.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )

            if fileManager.fileExists(atPath: outputURL.path) {
                let handle = try FileHandle(forWritingTo: outputURL)
                defer {
                    try? handle.close()
                }
                try handle.seekToEnd()
                try handle.write(contentsOf: payload)
            } else {
                try payload.write(to: outputURL, options: .atomic)
            }
        } catch {
            // Smoke diagnostics are best-effort and must not alter app behavior.
        }
    }
}

private extension StatusMessage {
    var smokeToken: String {
        switch self {
        case .noPlainText:
            return "noPlainText"
        case .alreadyClean:
            return "alreadyClean"
        case .cleaned:
            return "cleaned"
        case .clipboardReadFailed:
            return "clipboardReadFailed"
        case .clipboardWriteFailed:
            return "clipboardWriteFailed"
        case .automationPermissionRequired:
            return "automationPermissionRequired"
        case .automationPermissionRequestDenied:
            return "automationPermissionRequestDenied"
        case .automationPermissionGranted:
            return "automationPermissionGranted"
        }
    }
}
