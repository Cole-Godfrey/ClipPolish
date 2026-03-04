import AppKit
import ClipPolishCore
import UniformTypeIdentifiers

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
        isPlainTextOnlyPayload() ? .plainText : .nonText
    }

    func readPlainText() throws -> String {
        guard let value = pasteboard.string(forType: .string) else {
            throw SystemPasteboardGatewayError.readFailed
        }
        return value
    }

    func writePlainText(_ text: String, onlyIfCurrentMatches expectedCurrentText: String) throws {
        guard
            isPlainTextOnlyPayload(),
            pasteboard.string(forType: .string) == expectedCurrentText
        else {
            throw SystemPasteboardGatewayError.clipboardChanged
        }

        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            throw SystemPasteboardGatewayError.writeFailed
        }
    }

    private func isPlainTextOnlyPayload() -> Bool {
        guard
            let items = pasteboard.pasteboardItems,
            items.count == 1,
            let item = items.first
        else {
            return false
        }

        let types = item.types
        guard
            !types.isEmpty,
            types.allSatisfy({ type in
                guard let resolvedType = UTType(type.rawValue) else {
                    return false
                }
                return resolvedType.conforms(to: .plainText)
            }),
            pasteboard.string(forType: .string) != nil
        else {
            return false
        }

        return true
    }
}
