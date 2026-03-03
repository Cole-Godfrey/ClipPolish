# ClipPolish

ClipPolish is a lightweight macOS menu bar utility that cleans copied plain text before paste.

The current behavior is intentionally conservative: trim only leading/trailing whitespace and remove a small denylist of invisible Unicode scalars that commonly break pastes or tooling.

## Recommended Installation (Local Build)

ClipPolish is installed from source using the local app installer script. This avoids unsigned `.pkg` distribution issues and gives a stable app path for Accessibility permission.

Requirements:
- macOS 13+
- Xcode 15+ or Swift 5.9+

Install steps:

1. Clone this repository.
2. Run:

```bash
bash scripts/install-app.sh
```

3. Launch `ClipPolish.app` from `~/Applications`.
4. Confirm the menu bar icon appears.
5. In the menu bar app, enable `Enable Global Hotkey` (default shortcut: `Command` + `Shift` + `Option` + `V`).

Default install location: `~/Applications/ClipPolish.app`

Optional install commands:

```bash
# Install into /Applications (may require sudo)
bash scripts/install-app.sh --system-applications

# Build a debug app bundle and do not auto-launch
bash scripts/install-app.sh debug --no-run
```

## Required Setup: Accessibility Permission (For Hotkey)

Hotkey clean-and-paste requires macOS Accessibility permission. Without it, the global hotkey cannot post the paste event.

ClipPolish helps with setup:
- If permission is still missing, ClipPolish shows in-app guidance.
- You can use `Request Accessibility Permission`.
- You can use `Open Accessibility Settings`.

Complete these steps:

1. Open `System Settings -> Privacy & Security -> Accessibility`.
2. Enable `ClipPolish`.
3. If prompted, authenticate and confirm.
4. Quit and re-open ClipPolish so macOS reloads the new permission state.
5. Return to the target app and press the ClipPolish hotkey again.

If `ClipPolish` is not listed in Accessibility:

1. Quit ClipPolish.
2. Re-open the installed app bundle (`~/Applications/ClipPolish.app` by default).
3. Trigger the hotkey once, or click `Request Accessibility Permission`.
4. Re-check `System Settings -> Privacy & Security -> Accessibility` and enable `ClipPolish`.

Hotkey verification checklist:

1. Copy text with leading/trailing spaces in any text app.
2. Place the cursor in an input field.
3. Press the configured ClipPolish hotkey.
4. Confirm sanitized text is pasted.

Note: manual `Clean Clipboard Text` does not require Accessibility; only hotkey clean-and-paste does.

## Status

ClipPolish is at `1.0.1` and currently ships both manual cleanup and global hotkey clean-and-paste workflows.

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

## Development Setup

Additional development requirement:
- `ripgrep` (`rg`) for safety verification script

Build and run:

```bash
swift build
swift run ClipPolishApp
```

For hotkey and Accessibility testing during development, prefer the dedicated dev app bundle:

```bash
bash scripts/install-dev-app.sh
```

Optional flags:

```bash
bash scripts/install-dev-app.sh [debug|release] [--no-run]
```

This installs `~/Applications/ClipPolish Dev.app`, which provides a stable app path for Accessibility settings.
For hotkey testing, use the installed app bundle instead of `swift run`.

## Release Distribution

ClipPolish releases are source-first. Users install from source with `bash scripts/install-app.sh`.

## Test and Verify

```bash
swift test
make verify-phase3-hotkey-execution
```

When changing install scripts, also validate:

```bash
bash -n scripts/install-app.sh
bash -n scripts/install-dev-app.sh
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
