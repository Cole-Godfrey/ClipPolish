# ClipPolish

ClipPolish is a lightweight macOS menu bar utility that cleans copied plain text before paste.

The current behavior is intentionally conservative: trim only leading/trailing whitespace and remove a small denylist of invisible Unicode scalars that commonly break pastes or tooling.

## Status

ClipPolish is at `1.0.0` and currently ships both manual cleanup and global hotkey clean-and-paste workflows.

Implemented:
- Menu bar action: `Clean Clipboard Text`
- Global hotkey toggle and recorder (default: `Command` + `Shift` + `Option` + `V`)
- Hotkey clean-and-paste flow (sanitize clipboard, then post paste event)
- Hotkey-triggered Accessibility request flow when permission is missing
- Persistent permission guidance with manual steps and `Open Accessibility Settings` action
- Leading/trailing whitespace and newline trim
- Removal of `U+FEFF`, `U+200B`, `U+2060`, and `U+00AD`
- Mixed-format clipboard payload handling (plain text + rich text metadata)
- Non-text clipboard payloads are left untouched
- Local-only processing (no network calls, no clipboard history persistence)

## Requirements

- macOS 13+
- Xcode 15+ or Swift 5.9+
- `ripgrep` (`rg`) for safety verification script

## Build and Run

```bash
swift build
swift run ClipPolishApp
```

For Accessibility permission testing on macOS, prefer installing and running the dev app bundle:

```bash
bash scripts/install-dev-app.sh
```

Optional flags:

```bash
bash scripts/install-dev-app.sh [debug|release] [--no-run]
```

This installs `~/Applications/ClipPolish Dev.app`, which gives a stable app path for Accessibility settings.
For hotkey testing, use the installed app bundle instead of `swift run`.

## Release Installer

To produce a release installer package that installs the app into `/Applications`:

```bash
make build-release-installer
```

Artifact output: `dist/ClipPolish-<version>.pkg`.

macOS privacy policy does not allow installers to auto-enable Accessibility for normal consumer installs.
ClipPolish installer opens the Accessibility pane and prompts the user to enable ClipPolish manually.

On GitHub release publish, `.github/workflows/release-installer.yml` builds and attaches the `.pkg`.
For signed release uploads, configure repository secrets:
- `CLIPPOLISH_APP_SIGN_IDENTITY`
- `CLIPPOLISH_PKG_SIGN_IDENTITY`

## Test and Verify

```bash
swift test
make verify-phase3-hotkey-execution
```

When changing installer packaging or release automation, also validate:

```bash
bash -n scripts/build-release-installer.sh
bash -n scripts/install-dev-app.sh
bash -n packaging/macos/scripts/postinstall
```

## Safety Model

ClipPolish is designed to be predictable and low-risk.

- It only modifies plain-text payloads.
- It only writes back sanitized text when output differs from input.
- Hotkey automation is gated by macOS Accessibility permission checks.
- It does not persist clipboard history.
- It includes denylist-based safety checks to prevent accidental introduction of network/history behavior.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Security

See [SECURITY.md](SECURITY.md).

## License

Licensed under the MIT License. See [LICENSE](LICENSE).
