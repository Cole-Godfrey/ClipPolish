public enum ClipboardPayloadClassification: Equatable, Sendable {
    case plainText
    case noPlainText
}

public struct ClipboardPayloadClassifier: Sendable {
    public init() {}

    public func classify(_ payloadType: ClipboardPayloadType) -> ClipboardPayloadClassification {
        switch payloadType {
        case .plainText:
            return .plainText
        case .nonText:
            return .noPlainText
        }
    }
}
