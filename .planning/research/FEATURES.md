# Feature Research

**Domain:** Clipboard cleanup utilities and macOS menu-bar productivity tools  
**Researched:** 2026-03-02  
**Confidence:** MEDIUM

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Menu-bar presence with one-click action | Core interaction model in macOS utility space is persistent menu-bar access | LOW | Built with `NSStatusBar` or SwiftUI `MenuBarExtra`; must stay lightweight and always available |
| Plain-text cleanup mode | Users expect reliable "paste clean text" behavior | MEDIUM | Competitors expose plain-text or formatting-removal flows; for ClipPolish v1 keep rules conservative |
| Keyboard shortcut invocation | Power users expect fast no-mouse workflow | MEDIUM | Global shortcut and clean-and-paste flow may require Accessibility/Post Event permission handling |
| Privacy-first local processing | Clipboard tools are trusted only if data stays local | MEDIUM | Clear "no cloud/no telemetry" default for v1 reduces trust friction |
| Sensitive-content safeguards | Users expect password-manager or concealed content protection | MEDIUM | Ignore known concealed/transient pasteboard types and allow app exclusions |
| Non-text clipboard safety | Cleanup tool must not corrupt images/files/rich payload workflows | LOW | v1 should no-op non-plain-text payloads and avoid destructive rewrites |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Conservative-by-default cleanup profile | Builds trust by minimizing semantic text changes | MEDIUM | Restrict v1 transforms to edge trim + invisible/problematic character removal |
| Transparent cleanup preview (before/after) | Makes transformations auditable and reduces fear of hidden edits | MEDIUM | Show exact removed characters; optional in v1.x if MVP pressure is high |
| One-shot "Clean and Paste" with explicit trigger | Faster than manual copy/reopen/paste while keeping user control | MEDIUM | Depends on stable event-posting path and permission UX |
| Policy controls (per-rule and per-app) | Lets cautious users tune risk and avoid sensitive contexts | HIGH | Start with small settings surface: enable/disable hotkey, app exclusion list, safe defaults |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Full clipboard history in v1 | Common in clipboard manager products | Expands privacy risk, storage scope, and UX complexity beyond cleanup core | Keep v1 stateless (operate on current clipboard only) |
| Aggressive auto-normalization (quotes, punctuation, list rewriting) | Promises "better formatting" | High chance of changing intended meaning or code/text semantics | Keep conservative rule set; defer stylistic transforms to opt-in v2 |
| AI rewrite/classification of copied text | Marketed as smart productivity | Introduces nondeterminism and potential data egress concerns | Deterministic local regex/rule engine only |
| Cross-device/cloud sync | Convenience for multi-device workflows | Increases security, encryption, conflict, and account complexity | Local-only v1; revisit only after trust and core behavior are validated |

## Feature Dependencies

```
[Menu Bar Action]
    └──requires──> [Clipboard Read/Write (NSPasteboard)]
                       └──requires──> [Conservative Cleanup Rule Engine]

[Clean-and-Paste Hotkey]
    ├──requires──> [Conservative Cleanup Rule Engine]
    └──requires──> [Global Shortcut + Event Posting Permission]

[Sensitive Content Safeguards] ──enhances──> [Clipboard Read/Write (NSPasteboard)]

[Aggressive Auto-Normalization] ──conflicts──> [Conservative Safety-First Behavior]
[Clipboard History Capture] ──conflicts──> [v1 Minimal Risk/Scope]
```

### Dependency Notes

- **Menu Bar Action requires Clipboard Read/Write:** core flow needs reliable read from `NSPasteboard.general` and atomic write-back of cleaned text.
- **Cleanup Rule Engine requires deterministic ordering:** trim and invisible-character removal should be stable and testable to avoid accidental text mutations.
- **Clean-and-Paste Hotkey requires permission-aware event pipeline:** global trigger and paste simulation depend on macOS input-event permission state and fallback UX.
- **Sensitive Content Safeguards enhance Clipboard Read/Write:** app exclusions and concealed/transient type ignores reduce accidental handling of secrets.
- **Aggressive Auto-Normalization conflicts with safety-first behavior:** stylistic transforms increase false positives and user distrust in a cleanup-first utility.
- **Clipboard History Capture conflicts with v1 minimal scope:** history storage changes threat model and adds retention/encryption requirements.

## MVP Definition

### Launch With (v1)

Minimum viable product — what is needed to validate the concept safely.

- [ ] Menu-bar utility with explicit "Clean Clipboard Text" action — validates daily utility without background surprises.
- [ ] Conservative cleanup rules (edge trim + invisible/problematic character removal only) — core promise of safe cleanup.
- [ ] Non-text passthrough/no-op behavior — prevents corruption of images/files/rich data.
- [ ] Optional global "Clean and Paste" hotkey — validates speed path for frequent use.
- [ ] Local-only operation and clear safety defaults — establishes trust early.

### Add After Validation (v1.x)

Features to add once core is working.

- [ ] Per-app exclusions and temporary bypass mode — add when users report sensitive-workflow collisions.
- [ ] Rule toggles and presets — add when users request personalization without semantics-changing transforms.
- [ ] Cleanup preview/undo for last operation — add if confidence concerns appear in early dogfooding.

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] Optional stylistic normalization (quotes/lists/punctuation) — only as explicit opt-in profile.
- [ ] URL cleanup module (tracking-parameter removal) — separate intent from plain-text sanitization.
- [ ] History/snippets/sync capabilities — only if product direction expands beyond cleanup utility.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Menu-bar clean action | HIGH | LOW | P1 |
| Conservative cleanup rules | HIGH | MEDIUM | P1 |
| Non-text safety guardrails | HIGH | LOW | P1 |
| Optional clean-and-paste hotkey | HIGH | MEDIUM | P1 |
| Local-only privacy posture | HIGH | LOW | P1 |
| App exclusions | MEDIUM | MEDIUM | P2 |
| Rule toggles/presets | MEDIUM | MEDIUM | P2 |
| Cleanup preview/undo | MEDIUM | MEDIUM | P2 |
| URL tracking cleanup | MEDIUM | MEDIUM | P3 |
| Full clipboard history | LOW (for cleanup-only v1) | HIGH | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | Competitor A | Competitor B | Our Approach |
|---------|--------------|--------------|--------------|
| Menu-bar utility pattern | **Pure Paste:** menu-bar utility for plain-text paste workflows | **Maccy:** menu-bar clipboard manager with keyboard access | Menu-bar first, minimal UI, explicit manual trigger |
| Plain-text cleanup | **Pure Paste:** automatic or manual formatting removal; can also remove invisible chars | **Maccy:** supports pasting selected history item without formatting | Conservative cleanup only; no broad style normalization in v1 |
| Privacy posture | **Pure Paste:** local processing positioning | **Maccy:** local/open source positioning | Local-only v1 with no account/sync surface |
| Sensitive-data handling | **Pure Paste:** preserves password-manager-related content; app exclusion controls | **Maccy:** ignores concealed/transient pasteboard types and configurable ignores | Default-safe ignore rules + optional app exclusions |
| Scope breadth | **Pure Paste:** focused on cleanup and paste behavior | **Maccy:** focused on history/search/pin flows | Stay cleanup-focused; defer history/snippets/sync to later phases |

## Sources

- Maccy README (features, keyboard flow, ignore types): https://github.com/p0deje/Maccy
- Pure Paste product page/FAQ (cleanup scope, limits, exclusions): https://sindresorhus.com/pure-paste
- Raycast Clipboard History (supported types, encryption, retention, password-manager ignore): https://www.raycast.com/core-features/clipboard-history
- Raycast manual Clipboard History settings (disabled apps, retention, hotkeys): https://manual.raycast.com/windows/clipboard-history
- Alfred Clipboard History (privacy-default off, retention windows, ignore apps): https://www.alfredapp.com/help/features/clipboard/
- Paste help center (search/filter by app/type/time, pinboards, iCloud-private sync): https://pasteapp.io/help/explore-paste
- Apple `NSStatusBar` docs (menu-bar utility primitives): https://developer.apple.com/documentation/AppKit/NSStatusBar
- Apple pasteboard docs index (`NSPasteboard`): https://developer.apple.com/documentation/appkit/documents-data-and-pasteboard
- Apple event monitoring guide (global key monitoring and accessibility caveat): https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/MonitoringEvents/MonitoringEvents.html

---
*Feature research for: clipboard cleanup utilities and macOS menu-bar productivity tools*  
*Researched: 2026-03-02*
