import Foundation

public enum LineEndingStyle: Sendable {
    case preserve
    case lf
    case crlf
}

public struct TextSanitizer: Sendable {
    private let removableScalars: Set<UnicodeScalar>

    public init(removableScalars: Set<UnicodeScalar> = RemovableScalarList.v1) {
        self.removableScalars = removableScalars
    }

    public func sanitize(_ text: String, lineEndingStyle: LineEndingStyle = .preserve) -> String {
        let filtered = filterRemovableScalars(in: text)
        let trimmed = filtered.trimmingCharacters(in: .whitespacesAndNewlines)
        return applyLineEndingStyle(lineEndingStyle, to: trimmed)
    }

    private func filterRemovableScalars(in text: String) -> String {
        let filteredScalars = text.unicodeScalars.filter { !removableScalars.contains($0) }
        return String(String.UnicodeScalarView(filteredScalars))
    }

    private func applyLineEndingStyle(_ style: LineEndingStyle, to text: String) -> String {
        switch style {
        case .preserve:
            return text
        case .lf:
            return text
                .replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
        case .crlf:
            let normalizedLF = text
                .replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
            return normalizedLF.replacingOccurrences(of: "\n", with: "\r\n")
        }
    }
}
