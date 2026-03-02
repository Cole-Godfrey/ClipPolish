public struct CleanupChangeSummary: Equatable, Sendable {
    public let scalarsRemoved: Int
    public let leadingCharactersTrimmed: Int
    public let trailingCharactersTrimmed: Int

    public init(
        scalarsRemoved: Int = 0,
        leadingCharactersTrimmed: Int = 0,
        trailingCharactersTrimmed: Int = 0
    ) {
        self.scalarsRemoved = scalarsRemoved
        self.leadingCharactersTrimmed = leadingCharactersTrimmed
        self.trailingCharactersTrimmed = trailingCharactersTrimmed
    }

    public var totalCharactersRemoved: Int {
        scalarsRemoved + leadingCharactersTrimmed + trailingCharactersTrimmed
    }
}

public enum CleanupResult: Equatable, Sendable {
    case cleaned(CleanupChangeSummary)
    case alreadyClean
    case noPlainText
    case clipboardReadFailed
    case clipboardWriteFailed
}
