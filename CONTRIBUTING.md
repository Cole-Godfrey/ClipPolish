# Contributing to ClipPolish

Thanks for contributing.

## Development Setup

1. Install Xcode 15+ (or Swift 5.9+ toolchain) on macOS 13+.
2. Clone the repo.
3. Build and run tests:

```bash
swift build
swift test
```

4. For hotkey/Accessibility testing, run the dev app bundle:

```bash
bash scripts/install-dev-app.sh
```

5. Run safety verification before opening a PR:

```bash
make verify-phase3-hotkey-execution
```

## Pull Request Guidelines

- Keep PRs focused and small.
- Add or update tests for behavior changes.
- Update docs when behavior or workflows change.
- Update `CHANGELOG.md` in the `Unreleased` section for user-visible changes.
- Ensure CI passes.
- If your PR changes installer/release scripts, validate shell syntax:

```bash
bash -n scripts/build-release-installer.sh
bash -n scripts/install-dev-app.sh
bash -n packaging/macos/scripts/postinstall
```

## Code Quality Expectations

- Preserve conservative cleanup behavior unless there is explicit discussion and agreement.
- Preserve hotkey safety boundaries:
  - Do not bypass Accessibility permission checks for synthetic paste events.
  - Keep hotkey execution single-flight to avoid re-entrant duplicate actions.
- Do not introduce clipboard history persistence.
- Do not add network calls to clipboard cleanup paths.
- Prefer deterministic, testable behavior.

See [QUALITY_GATES.md](QUALITY_GATES.md) for required checks.

## Branching and Commits

- Use descriptive branch names (`feature/...`, `fix/...`, `docs/...`).
- Write clear commit messages in imperative voice.

## Community Standards

By participating, you agree to follow [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
