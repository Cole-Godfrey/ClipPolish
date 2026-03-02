# Project Research Summary

**Project:** ClipPolish
**Domain:** macOS menu-bar clipboard text cleanup utility
**Researched:** 2026-03-02
**Confidence:** MEDIUM

## Executive Summary

ClipPolish is a focused macOS utility, not a general clipboard manager. The strongest implementation pattern is a native Swift app with menu-bar-first interaction, deterministic text cleaning, and explicit user-triggered actions. The research consistently supports a trust-first approach: handle only plain text in v1, avoid aggressive normalization, and keep the app lightweight and local-only.

The recommended build strategy is conservative by design. Use Swift 6.2+, SwiftUI `MenuBarExtra`/AppKit clipboard APIs, and a layered architecture that isolates OS integrations behind adapters. Ship manual "Clean Clipboard Text" first, with optional clean-and-paste hotkey only after permission-aware flow control is stable. This sequence delivers user value early while minimizing brittle system-integration risk.

Primary risks are non-text clipboard corruption, meaning-changing sanitization, and flaky hotkey/paste automation due to permissions and timing. Mitigation is clear: strict type-gating and write-on-change only, explicit minimal rule set with fixture tests, manual path always available, and preflighted permission/focus checks before synthetic paste actions.

## Key Findings

### Recommended Stack

The stack should remain fully native: Swift for logic, AppKit/SwiftUI for menu and clipboard interaction, ServiceManagement for login behavior, and SPM for dependency management. This is the lowest-complexity path with the best long-term compatibility for a macOS-only utility.

**Core technologies:**
- `Swift 6.2.x`: app logic, rule engine, and concurrency-safe orchestration — best native fit with strong tooling.
- `SwiftUI MenuBarExtra + AppKit NSPasteboard`: menu-bar UX and clipboard access — official APIs purpose-built for this app shape.
- `ServiceManagement SMAppService`: launch-at-login behavior on macOS 13+ — modern Apple-supported replacement for legacy startup methods.
- `Swift Package Manager`: dependency/build integration — default ecosystem standard with minimal operational overhead.
- `XCTest/Swift Testing + SwiftLint + swift-format`: quality guardrails — needed to prevent subtle sanitizer regressions.

### Expected Features

Research points to a compact MVP that proves reliability and trust before feature breadth.

**Must have (table stakes):**
- Menu-bar clean action — users expect one-click access in this utility category.
- Conservative plain-text cleanup — core value proposition and trust anchor.
- Non-text safety no-op behavior — prevents breaking image/file/rich-text workflows.
- Optional keyboard invocation (clean-and-paste) — expected by power users, but optional at launch.
- Local-only privacy posture — required for clipboard utility trust.

**Should have (competitive):**
- Cleanup preview/visibility — improves confidence in transformations.
- Per-app exclusions and rule toggles — practical safety controls once baseline is stable.

**Defer (v2+):**
- Clipboard history/snippets/sync — scope and privacy expansion outside v1 goal.
- Aggressive normalization/AI rewriting — too high risk for semantic drift in a safety-first utility.

### Architecture Approach

Use a layered architecture: passive UI, action-oriented application coordinator, pure domain cleaning pipeline, and protocol-based infrastructure adapters for pasteboard/hotkey/permissions. This keeps core behavior testable and deterministic while containing OS fragility to replaceable boundaries.

**Major components:**
1. `ClipboardCoordinator + Use Cases` — orchestrates manual clean and optional clean-and-paste flows.
2. `TextCleaner` domain pipeline — ordered, deterministic rules with explicit scope.
3. `Pasteboard/Hotkey/Permissions gateways` — isolate AppKit/CoreGraphics/Accessibility integration edge cases.

### Critical Pitfalls

1. **Non-text payload clobbering** — type-gate strictly, no-op non-text clipboard states, and only write when sanitized text differs.
2. **Meaning-changing sanitization** — restrict v1 to edge-trim + known problematic invisibles, with fixture/snapshot coverage.
3. **Clipboard feedback loops** — prefer manual trigger default; track `changeCount` and ignore self-originated writes.
4. **Clean-and-paste race conditions** — enforce read->sanitize->write->verify->paste sequencing with a bounded delay.
5. **Permission mismatch failures** — preflight capabilities and keep manual clean path as guaranteed fallback.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Clipboard Core Safety
**Rationale:** Every other capability depends on trustworthy text transformation and safe clipboard handling.
**Delivers:** Deterministic cleaner, explicit rule set, non-text no-op guardrails, unit/integration fixtures.
**Addresses:** Menu clean action core behavior, conservative cleanup rules, non-text safety.
**Avoids:** Non-text clobbering, semantic mutation regressions.

### Phase 2: Menu-Bar Runtime and Lifecycle
**Rationale:** Establish stable product shell before adding automation complexity.
**Delivers:** Persistent status item, manual clean command, quit/recovery UX, settings persistence skeleton.
**Uses:** `MenuBarExtra` or `NSStatusItem`, `UserDefaults/@AppStorage`.
**Implements:** `MenuBarUI`, `ClipboardCoordinator`, `SettingsStore` wiring.
**Avoids:** Status-item disappearance, inaccessible app lifecycle states, early feedback-loop mistakes.

### Phase 3: Hotkey and Clean-and-Paste Automation
**Rationale:** High user value but highest platform variance; should come after stable manual path.
**Delivers:** Optional global shortcut, clean-and-paste pipeline, race-condition safeguards, cross-app validation matrix.
**Uses:** `KeyboardShortcuts` or Carbon hotkey adapter + CoreGraphics/AX checks.
**Implements:** `HotkeyService`, `PermissionsGateway`, `CleanAndPasteUseCase`.
**Avoids:** Permission silent-failure and stale-paste timing defects.

### Phase 4: Privacy, Permissions, and Policy Controls
**Rationale:** Hardens trust model after core behavior is proven in real usage.
**Delivers:** Just-in-time permission UX, app exclusions, privacy disclosures, safe logging policy.
**Addresses:** Sensitive-content safeguards, local-only trust posture, policy controls.
**Avoids:** Privacy-hostile access patterns, unclear permission states, support churn.

### Phase 5: Hardening and v1.x Differentiators
**Rationale:** Add confidence and quality features only after core flows are reliable.
**Delivers:** Cleanup preview/undo, broader regression corpus, performance tuning, launch-at-login polish.
**Addresses:** Differentiators without expanding scope into history/sync.
**Avoids:** Shipping "looks done" flows without reliability depth.

### Phase Ordering Rationale

- Dependencies are strict: safe cleaning and type handling must precede UI shell, which must precede automation.
- Architecture boundaries are easiest to enforce early when domain/infrastructure contracts are defined in Phase 1.
- Risk is front-loaded on trust and safety, then incrementally expanded to permissions and automation.
- This ordering directly maps PITFALLS phase warnings to prevention-first delivery.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3:** Permission and event-posting behavior varies by macOS context; requires focused API validation and fallback design.
- **Phase 4:** TCC/permission UX and app-exclusion policy details need tighter implementation-level decisions.
- **Phase 5:** Launch-at-login approval-state behavior and long-tail reliability heuristics need targeted validation.

Phases with standard patterns (skip research-phase):
- **Phase 1:** Deterministic text-cleaning pipeline and pasteboard type-gating are well-understood patterns.
- **Phase 2:** Menu-bar shell, command routing, and settings persistence are mature macOS patterns.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Anchored in official Apple docs/SDK headers and concrete release references. |
| Features | MEDIUM | Strong market signal from competitors, but still product-strategy inference for this specific scope. |
| Architecture | HIGH | Core layering and API boundary guidance is consistent and validated by platform primitives. |
| Pitfalls | MEDIUM | Pitfalls are credible and recurring, but some failure modes are context-dependent and need empirical validation. |

**Overall confidence:** MEDIUM

### Gaps to Address

- **Invisible character scope:** Final v1 removal allowlist/code-point set needs explicit validation against real daily samples.
- **Permission matrix:** Exact behavior for hotkey capture vs synthetic paste across macOS versions and runtime contexts should be test-mapped.
- **Paste timing model:** Delay/focus heuristics need empirical tuning across target apps (Terminal, Notes, browsers, editors).
- **Launch-at-login edge cases:** Approval-state UX and failure handling should be validated on clean machines before broad rollout.

## Sources

### Primary (HIGH confidence)
- Apple Developer docs: `MenuBarExtra`, `NSStatusItem`, `NSPasteboard`, `SMAppService` — API capabilities and platform constraints.
- Xcode SDK headers (`NSPasteboard.h`, `SMAppService.h`, `AXUIElement.h`, `CGEvent.h`, `CarbonEvents.h`) — concrete behavioral contracts and availability.
- Swift/tooling releases: Swift 6.2.x, `swift-format` 602.0.0, SwiftLint 0.63.2 — version baselines.

### Secondary (MEDIUM confidence)
- `sindresorhus/KeyboardShortcuts` and `LaunchAtLogin-Modern` release docs — practical implementation shortcuts for optional features.
- Competitor docs/pages (Maccy, Pure Paste, Raycast, Alfred, Paste) — table-stakes and differentiation signal.

### Tertiary (LOW confidence)
- Apple Developer Forums thread on input monitoring/event posting behavior — useful cautionary evidence, should not be sole implementation authority.

---
*Research completed: 2026-03-02*
*Ready for roadmap: yes*
