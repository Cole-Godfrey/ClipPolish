# Versioning Policy

ClipPolish uses Semantic Versioning (`MAJOR.MINOR.PATCH`).

## Rules

- `MAJOR`: incompatible API or behavior changes.
- `MINOR`: backward-compatible feature additions.
- `PATCH`: backward-compatible fixes.

## Historical Pre-1.0 Behavior

Before `1.0.0`, while major version was `0`, minor versions could include breaking changes.
Those breaking changes still needed to be clearly documented in `CHANGELOG.md`.

## Tagging

- Release tags use `vMAJOR.MINOR.PATCH` (example: `v1.0.0`).
- Every release tag must have a matching changelog entry.
