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

4. Run safety verification before opening a PR:

```bash
make verify-phase1-safety
```

## Pull Request Guidelines

- Keep PRs focused and small.
- Add or update tests for behavior changes.
- Update docs when behavior or workflows change.
- Update `CHANGELOG.md` in the `Unreleased` section for user-visible changes.
- Ensure CI passes.

## Code Quality Expectations

- Preserve conservative cleanup behavior unless there is explicit discussion and agreement.
- Do not introduce clipboard history persistence.
- Do not add network calls to clipboard cleanup paths.
- Prefer deterministic, testable behavior.

See [QUALITY_GATES.md](QUALITY_GATES.md) for required checks.

## Branching and Commits

- Use descriptive branch names (`feature/...`, `fix/...`, `docs/...`).
- Write clear commit messages in imperative voice.

## Community Standards

By participating, you agree to follow [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
