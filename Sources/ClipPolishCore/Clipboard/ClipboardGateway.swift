public enum ClipboardPayloadType: Equatable, Sendable {
    case plainText
    case nonText
}

public protocol ClipboardGateway: Sendable {
    func currentPayloadType() -> ClipboardPayloadType
    func readPlainText() throws -> String
    func writePlainText(_ text: String, onlyIfCurrentMatches expectedCurrentText: String) throws
}
