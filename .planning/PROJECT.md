# ClipPolish

## What This Is

ClipPolish is a lightweight macOS menu-bar utility that cleans copied plain text before paste. It focuses on safe sanitization of problematic clipboard content, including trimming edge whitespace and removing invisible characters that break formatting or tools. v1 is designed for personal daily use with manual triggering via menu action and an optional clean-and-paste hotkey.

## Core Value

Clipboard cleanup should be safe and predictable: remove paste-breaking artifacts without changing the intended text.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] User can clean current plain-text clipboard content from the menu bar.
- [ ] Clipboard cleanup trims leading and trailing whitespace only (preserve internal spacing/newlines).
- [ ] Clipboard cleanup removes invisible/problematic characters that commonly break pastes and tools.
- [ ] User can optionally enable a hotkey to clean and paste into the active app.
- [ ] Non-text clipboard payloads are ignored safely without corrupting clipboard behavior.

### Out of Scope

- Quote normalization in v1 — deferred to v2 to keep behavior conservative and avoid unintended text changes.
- Rich text, files, and images — v1 only processes plain text clipboard content.
- Public multi-user onboarding/release workflows — v1 is optimized for personal use first.

## Context

The immediate pain is pastes that break formatting or downstream tools due to hidden characters and inconsistent clipboard text quality. The target user for v1 is the project owner (personal utility), with the primary success condition being trustworthy day-to-day use. The default operating model is conservative and manual-first to prioritize reliability over aggressive normalization.

## Constraints

- **Platform**: macOS only — initial release is a menu-bar utility for one desktop OS.
- **Data Type**: Plain text only — avoids high-complexity clipboard type handling in v1.
- **Behavior**: Manual trigger by default — user control reduces accidental transformations.
- **Safety**: Never break text — conservative transformations only in v1.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Build v1 for personal use first | Optimize for fast iteration on real daily workflow pain | — Pending |
| Ship macOS-only menu-bar app in v1 | Narrow platform scope to reduce build and maintenance complexity | — Pending |
| Use conservative cleanup policy | Reliability is more important than aggressive normalization | — Pending |
| Defer quote normalization to v2 | Avoid semantic/style changes while validating core utility | — Pending |
| Make clean-and-paste hotkey optional | Keep workflow flexible without forcing keyboard-first interaction | — Pending |

---
*Last updated: 2026-03-02 after initialization*
