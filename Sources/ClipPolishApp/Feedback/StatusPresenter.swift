import SwiftUI

@MainActor
protocol StatusMessagePresenting: AnyObject {
    func show(_ message: StatusMessage)
}

@MainActor
final class StatusPresenter: ObservableObject, StatusMessagePresenting {
    @Published private(set) var currentMessage: StatusMessage?
    private var clearTask: Task<Void, Never>?
    private let displayDurationNanoseconds: UInt64

    init(displayDurationNanoseconds: UInt64 = 2_000_000_000) {
        self.displayDurationNanoseconds = displayDurationNanoseconds
    }

    func show(_ message: StatusMessage) {
        currentMessage = message
        clearTask?.cancel()
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
