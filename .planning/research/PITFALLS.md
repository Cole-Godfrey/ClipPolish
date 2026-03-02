# Pitfalls Research

**Domain:** Clipboard sanitization + macOS menu-bar utility behavior
**Researched:** 2026-03-02
**Confidence:** MEDIUM

## Suggested Roadmap Phase Labels

- **Phase 1 - Clipboard Core Safety:** conservative text transforms, type gating, no-op behavior
- **Phase 2 - Menu-Bar Runtime:** status item lifecycle, menu UX, app lifecycle controls
- **Phase 3 - Hotkey + Paste Flow:** global shortcut handling and clean-and-paste sequencing
- **Phase 4 - Privacy + Permissions:** clipboard access policy, permission prompts, trust signals
- **Phase 5 - Hardening + Edge Cases:** Unicode, regression suite, reliability polishing

## Critical Pitfalls

### Pitfall 1: Clobbering Non-Text Clipboard Payloads

**What goes wrong:**
The app rewrites the pasteboard after reading plain text and accidentally removes other representations (RTF, HTML, file URLs, images), breaking expected paste behavior in other apps.

**Why it happens:**
Developers call `clearContents()` + `writeObjects()` as a blanket operation without strict type checks and without a no-op path for non-text payloads.

**How to avoid:**
- Process only when `public.utf8-plain-text` (or equivalent plain text type) is present.
- If clipboard is non-text-only, do nothing and surface a small status hint.
- Only write back when sanitized output differs from input.
- Add tests that copy/paste files, images, and rich text and verify they remain untouched.

**Warning signs:**
- "Copy image, run clean, paste fails" bug reports.
- File copy/paste works before utility launch and fails afterward.
- Clipboard type list shrinks to only plain text after cleaning.

**Phase to address:**
Phase 1 - Clipboard Core Safety

---

### Pitfall 2: Sanitization That Changes Meaning

**What goes wrong:**
Over-aggressive cleanup alters intended content (code indentation, markdown spacing, shell commands, multilingual text markers), reducing trust in the tool.

**Why it happens:**
Sanitization rules start as broad regexes ("remove all weird chars", "normalize all whitespace") instead of a tight allowlist/removal list.

**How to avoid:**
- Lock v1 scope to edge-trim + known problematic invisible characters only.
- Maintain an explicit removal set with rationale per code point.
- Add snapshot tests for code blocks, markdown tables, CSV, URLs, and multilingual samples.
- Gate new normalization rules behind opt-in settings.

**Warning signs:**
- Sanitized text diff is frequently larger than expected.
- Users report "cleaning broke my command/snippet."
- Regression tests fail on preserved internal whitespace/newlines.

**Phase to address:**
Phase 1 - Clipboard Core Safety

---

### Pitfall 3: Clipboard Feedback Loops

**What goes wrong:**
App observes clipboard change, writes cleaned text, triggers another change, and repeatedly re-processes content (looping, CPU spikes, flicker).

**Why it happens:**
Polling/observation logic does not track app-originated writes or content fingerprints.

**How to avoid:**
- In v1, keep default mode manual-trigger only.
- Track `changeCount` plus a hash of the last app-written payload.
- Ignore self-originated updates for a short debounce window.
- Emit one structured log event per sanitize operation for debugging loops.

**Warning signs:**
- Rapid repeated sanitize logs for identical text.
- Menu app uses noticeable CPU while idle.
- Clipboard appears to "fight" user copies.

**Phase to address:**
Phase 2 - Menu-Bar Runtime

---

### Pitfall 4: Clean-and-Paste Race Conditions

**What goes wrong:**
Hotkey invokes clean + synthetic paste, but target app receives stale clipboard data because paste fires before write propagation/focus stabilization.

**Why it happens:**
Flow is implemented as immediate "write then send Cmd+V" with no state checks or timing guardrails.

**How to avoid:**
- Sequence pipeline explicitly: read -> sanitize -> write -> verify change -> paste.
- Add a short configurable delay window (for example 30-120 ms) before paste dispatch.
- Abort with user feedback when active app/focus is ambiguous.
- Add integration tests for common targets (Notes, Terminal, browsers, code editors).

**Warning signs:**
- Intermittent "old text pasted" reports.
- Failure rate rises under CPU load or app switching.
- Works in dev/debug, flaky in release.

**Phase to address:**
Phase 3 - Hotkey + Paste Flow

---

### Pitfall 5: Permission Model Mismatch for Hotkeys and Event Posting

**What goes wrong:**
Global shortcut capture and/or synthetic key posting silently fails due to missing user-granted permissions or sandbox/runtime expectations.

**Why it happens:**
Implementation mixes APIs with different TCC behavior (monitoring vs posting vs accessibility APIs) without a preflight decision tree.

**How to avoid:**
- Pick minimal-permission APIs first for global shortcuts.
- Preflight required permissions before enabling feature toggles.
- Request permissions just-in-time with clear "why this is needed" text.
- Provide graceful fallback: clean-only action when paste automation is unavailable.

**Warning signs:**
- Hotkey setting appears enabled but does nothing.
- Permission prompt never appears, or appears repeatedly.
- Feature works only after manual System Settings changes.

**Phase to address:**
Phase 3 - Hotkey + Paste Flow (implementation), Phase 4 - Privacy + Permissions (hardening)

---

### Pitfall 6: Menu-Bar Lifecycle and Discoverability Gaps

**What goes wrong:**
App stays running but becomes hard to access or quit (missing status item, no Dock icon, no obvious recovery path), leading users to assume crashes.

**Why it happens:**
Agent-style app setup (`LSUIElement`) is added without robust lifecycle UX: strong status item ownership, redundant quit entry points, and first-run guidance.

**How to avoid:**
- Keep a strong reference to `NSStatusItem` for app lifetime.
- Always include `Quit` in status menu and optional emergency shortcut.
- Add onboarding note for menu bar overflow and how to restore access.
- Provide a troubleshooting menu action that opens permissions/settings.

**Warning signs:**
- Process visible in Activity Monitor but no usable UI entry point.
- Support requests: "App is running but icon disappeared."
- Forced termination becomes common for exiting.

**Phase to address:**
Phase 2 - Menu-Bar Runtime

---

### Pitfall 7: Privacy-Hostile Clipboard Access Patterns

**What goes wrong:**
App reads clipboard too frequently or without clear user intent, triggering trust issues, possible system prompts, and lower adoption.

**Why it happens:**
Design prioritizes convenience (background scanning) before privacy model and user expectations.

**How to avoid:**
- Keep v1 default strictly user-initiated read/clean operations.
- Avoid storing clipboard history unless explicitly enabled.
- Document data handling in-app ("never sent, never logged by default").
- Add a visible privacy mode that disables background checks entirely.

**Warning signs:**
- Users disable/uninstall after first permission/prompt friction.
- Telemetry (if any) shows low conversion on hotkey/automation enablement.
- Frequent privacy-related feedback despite low bug count.

**Phase to address:**
Phase 4 - Privacy + Permissions

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcode sanitize regex with no fixtures | Fast prototype | Hidden text corruption regressions | Only in throwaway spike branches |
| Poll clipboard continuously at high frequency | Simple implementation | Battery drain, loop risk, privacy friction | Never for default v1 behavior |
| Couple sanitize logic to UI action handlers | Fewer files initially | Un-testable core logic, slower iteration | Only before first test harness lands |
| Ship hotkey automation before permission UX | Demo looks complete | Silent failures and support burden | Never |

## Integration Gotchas

Common mistakes when connecting to platform subsystems.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `NSPasteboard` write path | Clearing contents unconditionally | Type-gate first; write only changed plain text |
| Global shortcut registration | Assuming one API covers all permission cases | Separate capture vs post-event capability checks |
| Synthetic paste dispatch | Sending paste without focus validation | Verify frontmost app/focus and fall back safely |
| `NSStatusItem` lifecycle | Storing item in weak/transient scope | Retain strongly for app lifetime |
| Agent app config (`LSUIElement`) | Hiding Dock icon without quit/recovery UX | Add explicit quit + troubleshooting actions |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| High-frequency clipboard polling | Idle CPU usage, battery drain | Manual trigger default; debounce polling | Noticeable on laptops within hours of use |
| Sanitizing huge payloads on main thread | Menu lag, spinner stutter | Size guardrails + background processing | Multi-MB clipboard text |
| Rebuilding status menu on every tick | UI jitter and delayed clicks | Recompute only on relevant state changes | Frequent state updates |

## Security Mistakes

Domain-specific security/privacy issues.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Logging raw clipboard text for debugging | Sensitive data leakage to logs | Redact or hash; disable raw logging in release |
| Persisting clipboard history by default | Secret retention beyond user intent | Make history explicit opt-in with clear retention policy |
| Sending clipboard fragments in telemetry/errors | Accidental exfiltration | Strip payloads from analytics and crash metadata |

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Silent mutation with no feedback | User mistrust when pasted text changes | Show brief "Cleaned" status with undo affordance |
| No collision handling for hotkeys | Feature appears broken | Detect conflicts and force user confirmation/rebind |
| Permission prompt at app launch | Immediate churn | Request permission at feature-use moment |
| No non-text explanation | Confusion when action does nothing | Explain "Only plain text is cleaned in v1" in menu |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Sanitizer:** Preserve internal whitespace/newlines while trimming edges.
- [ ] **Type handling:** Non-text clipboard payloads remain unchanged end-to-end.
- [ ] **Hotkey flow:** Clean-and-paste succeeds repeatedly across at least 5 target apps.
- [ ] **Permissions:** Denied/missing permissions show clear fallback behavior.
- [ ] **Lifecycle:** User can always access settings and quit, even with Dock icon hidden.
- [ ] **Privacy:** Release build does not log clipboard contents.

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Non-text payload clobbering | MEDIUM | Ship emergency patch to no-op non-text; add regression fixtures; notify users in release notes |
| Meaning-changing sanitization | HIGH | Roll back aggressive rule set; ship conservative defaults; add per-rule toggle and fixtures |
| Hotkey/paste automation failures | MEDIUM | Disable automation path by default; keep clean-only action; add guided permission repair |
| Missing status item access path | MEDIUM | Add relaunch/reset helper and always-visible quit path; improve first-run guidance |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Clobbering non-text clipboard payloads | Phase 1 - Clipboard Core Safety | Integration test proves image/file copy remains intact |
| Sanitization that changes meaning | Phase 1 - Clipboard Core Safety | Snapshot diff tests stay within conservative transform scope |
| Clipboard feedback loops | Phase 2 - Menu-Bar Runtime | No repeated sanitize events for same input under polling/manual use |
| Clean-and-paste race conditions | Phase 3 - Hotkey + Paste Flow | Repeated end-to-end runs paste newly sanitized value reliably |
| Permission model mismatch | Phase 3 + Phase 4 | Simulated denied/granted states produce expected fallback/prompt UX |
| Menu-bar lifecycle/discoverability gaps | Phase 2 - Menu-Bar Runtime | Users can recover UI and quit in all activation-policy modes |
| Privacy-hostile clipboard access patterns | Phase 4 - Privacy + Permissions | Privacy review confirms user-initiated access default and no sensitive logs |

## Sources

- Apple `NSPasteboard` documentation (types, write APIs, access behavior): https://developer.apple.com/documentation/appkit/nspasteboard/general
- Apple `NSPasteboard.PasteboardType` documentation (write/read type surface): https://developer.apple.com/documentation/appkit/nspasteboard/pasteboardtype
- Apple `NSStatusBar` documentation (status item constraints and availability): https://developer.apple.com/documentation/appkit/nsstatusbar
- Apple Launch Services keys (`LSUIElement`) documentation: https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/LaunchServicesKeys.html
- Apple Developer Forums discussion on input monitoring / post-event permissions in sandboxed menu-bar apps: https://developer.apple.com/forums/thread/789896
- Project context: `.planning/PROJECT.md`

---
*Pitfalls research for: clipboard sanitization + macOS menu-bar app behavior*
*Researched: 2026-03-02*
