# ClipPolish

## What This Is

ClipPolish is a macOS menu-bar utility that safely cleans plain-text clipboard content before paste. v1.0 ships both manual cleanup and an optional global clean-and-paste hotkey, with explicit non-text no-op behavior and permission-aware fallback UX.

## Core Value

Clipboard cleanup should be safe and predictable: remove paste-breaking artifacts without changing the intended text.

## Current State

- **Shipped version:** v1.0 (2026-03-04)
- **Milestone scope delivered:** 7 phases, 15 plans, 42 tasks
- **Verification posture:** deterministic phase chain is green; process-level smoke is capability-gated and explicit about SKIP reasons
- **Archive references:** `.planning/milestones/v1.0-ROADMAP.md`, `.planning/milestones/v1.0-REQUIREMENTS.md`, `.planning/milestones/v1.0-MILESTONE-AUDIT.md`

## Requirements

### Validated

- ✓ **CLIP-01, CLIP-02, CLIP-03, CLIP-05** - Manual cleanup command, conservative sanitizer behavior, and write-on-change guardrails shipped in v1.0.
- ✓ **CLIP-04** - Non-text and mixed-payload clipboard entries remain unchanged across manual and hotkey paths in v1.0.
- ✓ **INVK-01** - Persistent menu-bar cleanup entrypoint shipped in v1.0.
- ✓ **INVK-02** - Optional global hotkey with enable/disable persistence and conflict/disabled-state hardening shipped in v1.0.
- ✓ **INVK-03** - Hotkey clean-and-paste execution path shipped in v1.0.
- ✓ **INVK-04** - Permission-aware hotkey guidance and fallback behavior shipped in v1.0.
- ✓ **SAFE-01, SAFE-02, SAFE-03** - Local-only processing, no clipboard history, and minimal persisted settings shipped in v1.0.

### Active (Next Milestone Candidates)

- [ ] **CLNX-01** - Optional quote normalization profile.
- [ ] **CLNX-02** - Additional stylistic normalization presets.
- [ ] **CTRL-01** - Per-app exclusions for cleanup and hotkey actions.
- [ ] **CTRL-02** - Before/after preview and one-step undo.
- [ ] **VER-01** - Add a deterministic UI-scripting-enabled lane for smoke scenario PASS evidence when host capabilities are available.

### Out of Scope

- Rich text, images, and file payload transformation beyond no-op safety.
- Clipboard history manager features.
- Cloud sync/account features.
- Broad multi-user onboarding/distribution workflows beyond personal utility usage.

## Context

ClipPolish v1.0 is optimized for personal, daily reliability on macOS. The implementation is Swift-based (`Sources/`, `Tests/`, scripts) with approximately 4,830 LOC across runtime, tests, and verification scripts. Milestone build activity spanned 63 changed files with 5,702 insertions and 6 deletions from first feature commit to final v1.0 closeout commit range.

## Constraints

- **Platform:** macOS only.
- **Data Type:** Plain text cleanup only; non-text payloads must remain unchanged.
- **Safety:** Conservative transforms only; no semantic rewrites by default.
- **Execution:** Manual command remains available regardless of hotkey permission state.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Build v1 for personal use first | Optimize for fast iteration on real workflow pain | ✓ Good |
| Ship macOS-only menu-bar app in v1 | Keep scope narrow for reliability and shipping speed | ✓ Good |
| Use conservative cleanup policy | Prevent unintended text mutations | ✓ Good |
| Defer quote normalization to v2 | Avoid semantic/style drift in v1 | ✓ Good |
| Keep clean-and-paste hotkey optional | Preserve user control and predictable behavior | ✓ Good |
| Treat mixed/rich payloads as no-op unless plain-text proof exists | Protect clipboard representation integrity | ✓ Good |
| Reconcile runtime hotkey state from persisted preferences | Prevent disabled-state drift across relaunch and edits | ✓ Good |
| Split deterministic verification from optional smoke checks | Keep CI/dev defaults stable while allowing higher-fidelity host checks | ✓ Good |

---
*Last updated: 2026-03-04 after v1.0 milestone completion*
