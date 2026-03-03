# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Accessibility setup docs and in-app permission guidance now explicitly require quitting and re-opening ClipPolish after enabling Accessibility before hotkey clean-and-paste works.
- Project version references and bundle metadata now reflect `1.0.1`.

## [1.0.1] - 2026-03-03

### Added
- Source installer helper (`scripts/install-app.sh`) that builds and installs a local app bundle without `.pkg` packaging.
- Dev app installer helper (`scripts/install-dev-app.sh`) for a stable local app identity in Accessibility settings.
- Regression coverage for mixed-format clipboard payload sanitation and permission-status presentation behavior.

### Changed
- Hotkey permission guidance now includes explicit manual steps and an `Open Accessibility Settings` action.
- Permission-required and permission-denied status messages now remain visible until replaced.
- Accessibility guidance copy in the menu now reflects shipped behavior instead of phase-based wording.
- Documentation and release process now use source-first app installation (`bash scripts/install-app.sh`).

### Removed
- `.pkg` release installer workflow and related installer packaging guidance.

### Fixed
- Mixed-format clipboard payloads containing plain text are no longer misclassified as non-text.
- Hotkey invocation no longer fails silently when Accessibility permission is missing; it now requests permission during execution.

## [1.0.0] - 2026-03-03

### Added
- Initial OSS project metadata and community files.
- CI workflow for tests and safety checks.
- Release, quality gate, governance, and support documentation.
- Global hotkey settings controls in the menu bar, including persisted enabled state and shortcut.
- Hotkey execution coordinator for clean-and-paste automation with single-flight execution protection.
- Accessibility permission guidance and explicit request action for blocked hotkey automation.
- Phase verification targets in `Makefile`: `verify-phase2-hotkey-controls` and `verify-phase3-hotkey-execution`.
- App-level tests for hotkey settings, hotkey execution behavior, and permission guidance flows.

### Changed
- README and OSS workflow docs to document the shipped hotkey + permission behavior and current verification commands.
