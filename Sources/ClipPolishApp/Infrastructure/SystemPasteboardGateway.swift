import AppKit
import ClipPolishCore

enum SystemPasteboardGatewayError: Error {
    case readFailed
    case writeFailed
    case clipboardChanged
}

final class SystemPasteboardGateway: ClipboardGateway, @unchecked Sendable {
    private let pasteboard: NSPasteboard
    private let allowedTextTypes: Set<NSPasteboard.PasteboardType> = [
        .string,
        NSPasteboard.PasteboardType("public.utf8-plain-text"),
        NSPasteboard.PasteboardType("public.utf16-plain-text")
    ]

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func currentPayloadType() -> ClipboardPayloadType {
        guard
            let items = pasteboard.pasteboardItems,
            items.count == 1,
            let item = items.first
        else {
            return pasteboard.string(forType: .string) == nil ? .nonText : .plainText
        }

        let types = Set(item.types)
        guard !types.isEmpty else {
            return .nonText
        }

        return types.isSubset(of: allowedTextTypes) ? .plainText : .nonText
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
