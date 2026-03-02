# Architecture Research

**Domain:** macOS menu-bar clipboard utility
**Researched:** 2026-03-02
**Confidence:** HIGH (core APIs), MEDIUM (hotkey/paste UX edge cases)

## Standard Architecture

### System Overview

```
┌────────────────────────────────────────────────────────────────────────┐
│ Presentation Layer                                                     │
├────────────────────────────────────────────────────────────────────────┤
│  ┌────────────────────┐   ┌────────────────────┐   ┌────────────────┐ │
│  │ Menu Bar UI        │   │ Settings Window    │   │ Permission UI  │ │
│  │ (NSStatusItem/Menu)│   │ (SwiftUI/AppKit)   │   │ Prompts/State  │ │
│  └─────────┬──────────┘   └─────────┬──────────┘   └───────┬────────┘ │
├────────────┴─────────────────────────┴───────────────────────┴─────────┤
│ Application Layer (Coordinator + Use Cases)                            │
├────────────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │ ClipboardCoordinator                                              │ │
│  │ - CleanClipboardUseCase                                           │ │
│  │ - CleanAndPasteUseCase                                            │ │
│  │ - NonTextGuard / Error handling                                   │ │
│  └───────────────────────────────────────────────────────────────────┘ │
├────────────────────────────────────────────────────────────────────────┤
│ Domain + Infrastructure Layer                                          │
├────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌───────────────┐ │
│  │ TextCleaner  │ │ Pasteboard   │ │ HotkeySvc    │ │ Permissions   │ │
│  │ (pure rules) │ │ Gateway      │ │ (global key) │ │ Gateway       │ │
│  └──────────────┘ └──────────────┘ └──────────────┘ └───────────────┘ │
│  ┌──────────────┐                                                       │
│  │ SettingsStore │  (UserDefaults / AppStorage)                         │
│  └──────────────┘                                                       │
└────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `MenuBarUI` | User entry point (manual clean, status, quit) | `NSStatusBar.system.statusItem`, `NSMenu` |
| `ClipboardCoordinator` | Orchestrates menu/hotkey actions and guards | Main-actor service with explicit use-case calls |
| `CleanClipboardUseCase` | Read text, sanitize, write back safely | Calls `PasteboardGateway` + `TextCleaner` |
| `CleanAndPasteUseCase` | Clean then trigger paste | Use-case + `HotkeyService`/event posting adapter |
| `PasteboardGateway` | Isolate all `NSPasteboard` interactions | Adapter over `generalPasteboard`, `changeCount`, read/write APIs |
| `TextCleaner` | Deterministic, conservative text transforms | Pure Swift functions and rule pipeline |
| `HotkeyService` | Register optional global hotkey | `RegisterEventHotKey` adapter (Carbon) or equivalent wrapper |
| `PermissionsGateway` | Accessibility/input monitoring checks & prompts | `AXIsProcessTrustedWithOptions`, `CGPreflight*Access`/`CGRequest*Access` |
| `SettingsStore` | Persist user toggles and shortcuts | `UserDefaults` / `@AppStorage` |

## Recommended Project Structure

```
ClipPolish/
├── App/                         # App entry, lifecycle, dependency wiring
│   ├── ClipPolishApp.swift
│   └── AppBootstrap.swift
├── UI/                          # Presentation only
│   ├── MenuBar/
│   │   ├── StatusItemController.swift
│   │   └── MenuActions.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── SettingsViewModel.swift
├── Application/                 # Use cases + coordinator
│   ├── ClipboardCoordinator.swift
│   └── UseCases/
│       ├── CleanClipboardUseCase.swift
│       └── CleanAndPasteUseCase.swift
├── Domain/                      # Pure business logic
│   ├── Cleaning/
│   │   ├── TextCleaner.swift
│   │   └── CleaningRules.swift
│   └── Models/
│       └── CleaningResult.swift
├── Infrastructure/              # OS/framework adapters
│   ├── Pasteboard/
│   │   └── PasteboardGateway.swift
│   ├── Hotkey/
│   │   └── GlobalHotkeyService.swift
│   ├── Permissions/
│   │   └── AccessibilityPermissionService.swift
│   └── Persistence/
│       └── SettingsStore.swift
└── Tests/
    ├── DomainTests/
    ├── ApplicationTests/
    └── IntegrationTests/
```

### Structure Rationale

- **`Domain/`:** Keeps cleanup behavior deterministic and easy to test without macOS APIs.
- **`Infrastructure/`:** Contains all fragile OS integration points behind replaceable protocols.
- **`Application/`:** Prevents UI from owning side-effectful flows and permission logic.
- **`UI/`:** Focuses on menu/settings rendering and action dispatch only.

## Architectural Patterns

### Pattern 1: Ports and Adapters for OS APIs

**What:** Keep `NSPasteboard`, hotkey registration, and accessibility checks behind protocol boundaries.
**When to use:** Always for menu-bar utilities that depend on AppKit/CoreGraphics services.
**Trade-offs:** Slightly more boilerplate, much lower regression risk and better testability.

**Example:**
```swift
protocol PasteboardGateway {
    func readPlainText() -> String?
    func writePlainText(_ value: String)
    func changeCount() -> Int
}
```

### Pattern 2: Deterministic Cleaning Pipeline

**What:** Treat cleanup as ordered, pure transformation rules.
**When to use:** Any text-sanitization flow where trust and predictability matter.
**Trade-offs:** Less "smart" correction, fewer surprising edits.

**Example:**
```swift
func clean(_ input: String) -> String {
    trimEdgeWhitespace(removeProblematicInvisibles(input))
}
```

### Pattern 3: Action-Oriented Coordinator

**What:** One coordinator handles manual clean and optional clean-and-paste actions.
**When to use:** Small local apps with multiple triggers for same core behavior.
**Trade-offs:** Coordinator can become a god-object if boundaries are ignored.

## Data Flow

### Request Flow

```
[Menu Click or Hotkey]
    ↓
[ClipboardCoordinator]
    ↓
[PasteboardGateway.readPlainText]
    ↓
[TextCleaner.clean]
    ↓
[PasteboardGateway.writePlainText]
    ↓
[Optional Paste Action via Hotkey/Event Adapter]
    ↓
[UI status update + log event]
```

### State Management

```
[SettingsStore]
    ↓ (observe/load)
[ClipboardCoordinator] <-> [UI ViewModels]
    ↓
[Infrastructure services configured]
```

### Key Data Flows

1. **Manual clean flow:** Status item action -> read plain text -> sanitize -> write plain text -> show result.
2. **Clean-and-paste flow:** Hotkey event -> permission preflight -> sanitize clipboard -> synthesize paste keystroke.
3. **Non-text guard flow:** Clipboard read fails string check -> no-op -> user-visible "ignored non-text" state.

## Suggested Build Order

1. **Domain cleaning engine + tests first:** implement trimming + invisible-character removal rules with golden test fixtures.
2. **Pasteboard adapter + integration tests:** add safe plain-text read/write and non-text no-op behavior.
3. **Menu-bar shell:** wire `NSStatusItem` and manual clean action to coordinator.
4. **Settings + persistence:** toggle options (enable hotkey, launch at login) in `SettingsStore`.
5. **Optional hotkey + clean-and-paste path:** add global shortcut and paste synthesis behind explicit permission checks.
6. **Launch-at-login integration:** wire `SMAppService.mainApp` and approval-state UX.
7. **Hardening pass:** reliability telemetry/logging, error surfaces, and end-to-end manual test matrix.

## V1 Risk-Reduction Decisions

- **Manual trigger as the default path:** usable even if accessibility/input permissions are denied.
- **Plain text only:** avoids corrupting rich-text, files, or image payloads in v1.
- **Conservative rule set (trim edges + remove problematic invisibles):** minimizes semantic text changes.
- **No clipboard history in v1:** eliminates privacy/storage complexity and accidental data retention risk.
- **Protocol boundaries around OS APIs:** allows deterministic unit tests and easier regression isolation.
- **Permission-gated clean-and-paste:** run preflight checks before synthesizing events.
- **Single-process architecture for v1:** defer helper processes/daemons until concrete need exists.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Personal / single device | Single-process app; in-memory coordinator is sufficient. |
| 1k-10k installs | Add crash telemetry, richer diagnostics, and compatibility matrix by macOS version. |
| 100k+ installs | Consider optional helper split only for startup/background behavior complexity. |

### Scaling Priorities

1. **First bottleneck:** OS integration variance (permissions, event delivery). Fix with robust preflight checks and clearer fallback UX.
2. **Second bottleneck:** Rule regressions in text cleaning. Fix with fixture-based tests and explicit versioned rule changes.

## Anti-Patterns

### Anti-Pattern 1: UI Directly Calls AppKit/CoreGraphics Everywhere

**What people do:** Scatter pasteboard/hotkey calls across view and menu handlers.
**Why it's wrong:** Creates brittle behavior and hard-to-reproduce bugs.
**Do this instead:** Route all side effects through coordinator + infrastructure adapters.

### Anti-Pattern 2: Aggressive "Smart" Text Mutation in v1

**What people do:** Add quote normalization and formatting rewrites immediately.
**Why it's wrong:** Surprising output erodes trust in a utility that should be predictable.
**Do this instead:** Keep v1 transformations explicit, conservative, and test-backed.

### Anti-Pattern 3: Assume Hotkey/Paste Works Without Permissions

**What people do:** Register/emit events without access checks and no fallback.
**Why it's wrong:** Fails silently on many systems.
**Do this instead:** Preflight permissions, prompt intentionally, and keep manual clean path always available.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| AppKit (`NSStatusItem`, `NSPasteboard`) | Framework API adapters | Core of menu bar + clipboard behavior. |
| ServiceManagement (`SMAppService`) | Framework API adapter | Launch-at-login support for macOS 13+. |
| Accessibility / CoreGraphics | Permission + event adapters | Required for reliable global shortcut/paste synthesis paths. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `UI` ↔ `Application` | Commands + callback/state updates | Keep UI passive; no framework side effects in views. |
| `Application` ↔ `Domain` | Direct function calls | Domain stays pure and deterministic. |
| `Application` ↔ `Infrastructure` | Protocol-based adapters | Enables mocking and isolated integration tests. |

## Sources

- Apple Developer Documentation: `NSStatusItem` (AppKit) — https://docs.developer.apple.com/documentation/appkit/nsstatusitem
- Apple Developer Documentation: `NSPasteboard` (AppKit) — https://docs.developer.apple.com/documentation/appkit/nspasteboard
- Apple Developer Documentation: `SMAppService` (ServiceManagement) — https://docs.developer.apple.com/documentation/servicemanagement/smappservice
- Xcode macOS SDK header: `SMAppService.h` (macOS 13+ login items, status, approval model) — `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk/System/Library/Frameworks/ServiceManagement.framework/Versions/A/Headers/SMAppService.h`
- Xcode macOS SDK header: `NSPasteboard.h` (`generalPasteboard`, `changeCount`, read/write APIs) — `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk/System/Library/Frameworks/AppKit.framework/Versions/C/Headers/NSPasteboard.h`
- Xcode macOS SDK header: `AXUIElement.h` (`AXIsProcessTrustedWithOptions`) — `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Headers/AXUIElement.h`
- Xcode macOS SDK header: `CarbonEvents.h` (`RegisterEventHotKey`) — `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Headers/CarbonEvents.h`
- Xcode macOS SDK header: `CGEvent.h` (`CGEventPost`, event access preflight/request APIs) — `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk/System/Library/Frameworks/CoreGraphics.framework/Versions/A/Headers/CGEvent.h`

---
*Architecture research for: macOS menu-bar clipboard utility*
*Researched: 2026-03-02*
