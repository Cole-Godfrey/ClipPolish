import AppKit
import ClipPolishCore

enum SystemPasteboardGatewayError: Error {
    case readFailed
    case writeFailed
    case clipboardChanged
}

final class SystemPasteboardGateway: ClipboardGateway, @unchecked Sendable {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func currentPayloadType() -> ClipboardPayloadType {
        pasteboard.string(forType: .string) == nil ? .nonText : .plainText
    }

    func readPlainText() throws -> String {
        guard let value = pasteboard.string(forType: .string) else {
            throw SystemPasteboardGatewayError.readFailed
        }
        return value
    }

    func writePlainText(_ text: String, onlyIfCurrentMatches expectedCurrentText: String) throws {
        guard pasteboard.string(forType: .string) == expectedCurrentText else {
            throw SystemPasteboardGatewayError.clipboardChanged
        }

        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            throw SystemPasteboardGatewayError.writeFailed
        }
    }
}
