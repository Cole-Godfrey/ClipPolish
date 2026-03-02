import ClipPolishCore

enum StatusMessage: Equatable, Sendable {
    case noPlainText
    case alreadyClean
    case cleaned(totalCharactersRemoved: Int)
    case clipboardReadFailed
    case clipboardWriteFailed

    var displayText: String {
        switch self {
        case .noPlainText:
            return "No plain text to clean"
        case .alreadyClean:
            return "Already clean"
        case let .cleaned(totalCharactersRemoved):
            return "Cleaned clipboard text (\(totalCharactersRemoved) removed)"
        case .clipboardReadFailed:
            return "Could not read clipboard text"
        case .clipboardWriteFailed:
            return "Could not update clipboard text"
        }
    }

    static func fromCleanupResult(_ result: CleanupResult) -> StatusMessage {
        switch result {
        case let .cleaned(summary):
            return .cleaned(totalCharactersRemoved: summary.totalCharactersRemoved)
        case .alreadyClean:
            return .alreadyClean
        case .noPlainText:
            return .noPlainText
        case .clipboardReadFailed:
            return .clipboardReadFailed
        case .clipboardWriteFailed:
            return .clipboardWriteFailed
        }
    }
}
