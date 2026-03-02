import Foundation

public struct CleanupService: Sendable {
    private let gateway: any ClipboardGateway
    private let classifier: ClipboardPayloadClassifier
    private let sanitizer: TextSanitizer
    private let lineEndingStyle: LineEndingStyle

    public init(
        gateway: any ClipboardGateway,
        classifier: ClipboardPayloadClassifier = ClipboardPayloadClassifier(),
        sanitizer: TextSanitizer = TextSanitizer(),
        lineEndingStyle: LineEndingStyle = .preserve
    ) {
        self.gateway = gateway
        self.classifier = classifier
        self.sanitizer = sanitizer
        self.lineEndingStyle = lineEndingStyle
    }

    public func cleanCurrentClipboardText() -> CleanupResult {
        let payloadType = gateway.currentPayloadType()
        guard classifier.classify(payloadType) == .plainText else {
            return .noPlainText
        }

        let originalText: String
        do {
            originalText = try gateway.readPlainText()
        } catch {
            return .clipboardReadFailed
        }

        let sanitizedText = sanitizer.sanitize(originalText, lineEndingStyle: lineEndingStyle)
        guard sanitizedText != originalText else {
            return .alreadyClean
        }

        let summary = makeChangeSummary(original: originalText, sanitized: sanitizedText)

        do {
            try gateway.writePlainText(sanitizedText, onlyIfCurrentMatches: originalText)
        } catch {
            return .clipboardWriteFailed
        }

        return .cleaned(summary)
    }

    private func makeChangeSummary(original: String, sanitized: String) -> CleanupChangeSummary {
        let scalarsRemoved = original.unicodeScalars.reduce(into: 0) { count, scalar in
            if RemovableScalarList.v1.contains(scalar) {
                count += 1
            }
        }

        let filtered = String(
            String.UnicodeScalarView(
                original.unicodeScalars.filter { !RemovableScalarList.v1.contains($0) }
            )
        )
        let trimCounts = edgeTrimCounts(in: filtered)

        // Preserve a conservative invariant: summary metadata should not exceed observed removals.
        let totalRemoved = max(0, original.count - sanitized.count)
        let calculatedTotal = scalarsRemoved + trimCounts.leading + trimCounts.trailing

        if calculatedTotal <= totalRemoved {
            return CleanupChangeSummary(
                scalarsRemoved: scalarsRemoved,
                leadingCharactersTrimmed: trimCounts.leading,
                trailingCharactersTrimmed: trimCounts.trailing
            )
        }

        return CleanupChangeSummary(
            scalarsRemoved: scalarsRemoved,
            leadingCharactersTrimmed: max(0, totalRemoved - scalarsRemoved),
            trailingCharactersTrimmed: 0
        )
    }

    private func edgeTrimCounts(in text: String) -> (leading: Int, trailing: Int) {
        let characters = Array(text)
        guard !characters.isEmpty else {
            return (0, 0)
        }

        guard
            let firstKept = characters.firstIndex(where: { !isEdgeTrimCharacter($0) }),
            let lastKept = characters.lastIndex(where: { !isEdgeTrimCharacter($0) })
        else {
            return (characters.count, 0)
        }

        let leadingTrimmed = firstKept
        let trailingTrimmed = characters.count - lastKept - 1
        return (leadingTrimmed, trailingTrimmed)
    }

    private func isEdgeTrimCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { CharacterSet.whitespacesAndNewlines.contains($0) }
    }
}
