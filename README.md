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
6. Enable Accessibility permission when prompted, then click `Restart ClipPolish` from the menu to reload permission state before testing the hotkey.

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
- On launch, ClipPolish checks Accessibility permission and prompts if it is still missing.
- If permission is still missing, ClipPolish shows in-app guidance.
- You can use `Request Accessibility Permission`.
- You can use `Open Accessibility Settings`.
- You can use `Restart ClipPolish` after enabling permission so the app reloads permission state.

Complete these steps:

1. Open `System Settings -> Privacy & Security -> Accessibility`.
2. Enable `ClipPolish`.
3. If prompted, authenticate and confirm.
4. In the ClipPolish menu, click `Restart ClipPolish` so permission state is reloaded.
5. Return to the target app and press the ClipPolish hotkey again.

If `ClipPolish` is not listed in Accessibility:

1. Quit ClipPolish.
2. Re-open the installed app bundle (`~/Applications/ClipPolish.app` by default).
3. Trigger the hotkey once, or click `Request Accessibility Permission`.
4. Re-check `System Settings -> Privacy & Security -> Accessibility` and enable `ClipPolish`.

If hotkey still shows blocked even though `ClipPolish` is enabled:

1. Quit ClipPolish.
2. Run:

```bash
tccutil reset Accessibility com.clippolish.app
```

3. Re-open `~/Applications/ClipPolish.app`.
4. Click `Request Accessibility Permission` in the ClipPolish menu.
5. Re-enable ClipPolish in Accessibility if prompted.
6. Click `Restart ClipPolish`, then test the hotkey.

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
- Hotkey shortcut validation for system-reserved and app-menu conflicts
- Deterministic conflict guidance when a requested hotkey is blocked
- Invalid/conflicting shortcut updates preserve the persisted active shortcut
- Hotkey-triggered Accessibility request flow when permission is missing
- Startup Accessibility permission preflight and prompt flow
- Persistent permission guidance with manual steps and `Open Accessibility Settings` action
- Menu action: `Restart ClipPolish` to reload permission state
- Leading/trailing whitespace and newline trim
- Removal of `U+FEFF`, `U+200B`, `U+2060`, and `U+00AD`
- Mixed-format clipboard payload handling (plain text + rich text metadata)
- Non-text clipboard payloads are left untouched
- Optional process-level smoke verification harness for relaunch/permission/mixed-payload paths
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
make verify-phase7-hotkey-e2e
```

Phase 7 verification policy:
- `make verify-phase7-hotkey-e2e` is the default deterministic command. It runs phase-7 core invariants/hotkey tests and chains prior phase verification (`verify-phase6-hotkey-conflict` and below).
- `make verify-phase7-hotkey-smoke` is optional process-level smoke validation for real app-process hotkey behavior (relaunch, permission denied, mixed-payload cleanup).
- Smoke runs only when explicitly opted in:

```bash
CLIPPOLISH_RUN_HOTKEY_E2E=1 make verify-phase7-hotkey-smoke
```

- `SKIP:` output from the smoke harness is expected in CI or non-Aqua sessions (for example: headless shells, missing GUI permissions, or missing installed app bundle path).
- Smoke assertions fail only when execution actually runs and a scenario expectation is violated.

When changing install scripts, also validate:

```bash
bash -n scripts/install-app.sh
bash -n scripts/install-dev-app.sh
```

## Safety Model

ClipPolish is designed to be predictable and low-risk.

- It only modifies payloads that expose plain text and resolve to text UTTypes.
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
