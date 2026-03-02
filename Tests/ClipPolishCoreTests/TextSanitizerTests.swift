import Testing
@testable import ClipPolishCore

struct TextSanitizerTests {
    @Test
    func removesOnlyTheFixedV1Scalars() {
        let sanitizer = TextSanitizer()
        let input = "A\u{FEFF}B\u{200B}C\u{2060}D\u{00AD}E\u{200C}F"

        let output = sanitizer.sanitize(input, lineEndingStyle: .preserve)

        #expect(output == "ABCDE\u{200C}F")
    }

    @Test
    func trimsOnlyLeadingAndTrailingWhitespaceAndNewlines() {
        let sanitizer = TextSanitizer()
        let input = "\n  \tHello  \n\nWorld\t  \n"

        let output = sanitizer.sanitize(input, lineEndingStyle: .preserve)

        #expect(output == "Hello  \n\nWorld")
    }

    @Test
    func preservesInternalLineEndingStyleForLF() {
        let sanitizer = TextSanitizer()
        let input = "\nFirst line\nSecond line\n"

        let output = sanitizer.sanitize(input, lineEndingStyle: .preserve)

        #expect(output == "First line\nSecond line")
    }

    @Test
    func preservesInternalLineEndingStyleForCRLF() {
        let sanitizer = TextSanitizer()
        let input = "\r\nFirst line\r\nSecond line\r\n"

        let output = sanitizer.sanitize(input, lineEndingStyle: .preserve)

        #expect(output == "First line\r\nSecond line")
    }
}
