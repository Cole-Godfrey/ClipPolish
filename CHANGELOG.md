# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
