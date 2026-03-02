# ClipPolish

ClipPolish is a lightweight macOS menu bar utility that cleans copied plain text before paste.

The current behavior is intentionally conservative: trim only leading/trailing whitespace and remove a small denylist of invisible Unicode scalars that commonly break pastes or tooling.

## Status

ClipPolish is pre-1.0 and currently focused on a safe manual cleanup flow.

Implemented:
- Menu bar action: `Clean Clipboard Text`
- Leading/trailing whitespace and newline trim
- Removal of `U+FEFF`, `U+200B`, `U+2060`, and `U+00AD`
- Non-text clipboard payloads are left untouched
- Local-only processing (no network calls, no clipboard history persistence)

Planned:
- Optional global hotkey controls
- Clean-and-paste automation and permission guidance

## Requirements

- macOS 13+
- Xcode 15+ or Swift 5.9+
- `ripgrep` (`rg`) for safety verification script

## Build and Run

```bash
swift build
swift run ClipPolishApp
```

## Test and Verify

```bash
swift test
make verify-phase1-safety
```

## Safety Model

ClipPolish is designed to be predictable and low-risk.

- It only modifies plain-text payloads.
- It only writes back sanitized text when output differs from input.
- It does not persist clipboard history.
- It includes denylist-based safety checks to prevent accidental introduction of network/history behavior.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Security

See [SECURITY.md](SECURITY.md).

## License

Licensed under the MIT License. See [LICENSE](LICENSE).
