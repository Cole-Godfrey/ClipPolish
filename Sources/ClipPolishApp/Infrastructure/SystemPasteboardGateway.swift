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
        isTextPayloadWithPlainTextRepresentation() ? .plainText : .nonText
    }

    func readPlainText() throws -> String {
        guard let value = pasteboard.string(forType: .string) else {
            throw SystemPasteboardGatewayError.readFailed
        }
        return value
    }

    func writePlainText(_ text: String, onlyIfCurrentMatches expectedCurrentText: String) throws {
        guard
            isTextPayloadWithPlainTextRepresentation(),
            pasteboard.string(forType: .string) == expectedCurrentText
        else {
            throw SystemPasteboardGatewayError.clipboardChanged
        }

        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            throw SystemPasteboardGatewayError.writeFailed
        }
    }

    private func isTextPayloadWithPlainTextRepresentation() -> Bool {
        guard
            let items = pasteboard.pasteboardItems,
            !items.isEmpty,
            pasteboard.string(forType: .string) != nil
        else {
            return false
        }

        for item in items {
            let types = item.types
            guard !types.isEmpty else {
                return false
            }

            let onlyTextOrOpaque = types.allSatisfy { type in
                guard let resolvedType = UTType(type.rawValue) else {
                    // Allow opaque app-specific sidecars when a string representation exists.
                    return true
                }
                return !Self.isExplicitlyNonTextType(resolvedType)
            }

            if !onlyTextOrOpaque {
                return false
            }
        }

        return true
    }

    private static func isExplicitlyNonTextType(_ type: UTType) -> Bool {
        if type.conforms(to: .text) {
            return false
        }

        let blockedTypes: [UTType] = [
            .image,
            .movie,
            .audio,
            .pdf,
            .url,
            .fileURL,
            .archive,
            .executable
        ]

        return blockedTypes.contains(where: { type.conforms(to: $0) })
    }
}
