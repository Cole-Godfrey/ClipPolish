# Stack Research

**Domain:** macOS menu-bar clipboard text cleanup utility
**Researched:** 2026-03-02
**Confidence:** HIGH (platform choices), MEDIUM (point-version toolchain choices)

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Swift | 6.2.x (latest stable listed as 6.2.4) | App logic, text transforms, concurrency | Native performance, first-party support, and the lowest-friction path for a small macOS utility. |
| SwiftUI (`MenuBarExtra`) + AppKit (`NSPasteboard`) | macOS 13+ APIs | Menu-bar UI and clipboard read/write | `MenuBarExtra` is purpose-built for menu-bar apps, while `NSPasteboard` is the canonical clipboard API. |
| ServiceManagement (`SMAppService`) | macOS 13+ | Optional launch-at-login | Official modern API for login items on newer macOS; replaces legacy startup patterns. |
| Swift Package Manager | Bundled with current Swift toolchain | Dependency and build integration | Default dependency system in Xcode/Swift ecosystem; simplest for small apps. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `sindresorhus/KeyboardShortcuts` | 2.4.0 | User-customizable global hotkey | Use when enabling optional clean-and-paste hotkey. Skip for menu-only v1. |
| `sindresorhus/LaunchAtLogin-Modern` | 1.1.0 | SwiftUI toggle for launch-at-login | Use only if you expose a login toggle in Settings. |
| Foundation + Swift Regex | Built into toolchain | Conservative text cleanup rules | Use for safe whitespace and invisible-character transforms; avoid heavier parsing deps in v1. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Xcode | Build, sign, debug, profile | Use current stable 26.x line; keep CI and local on same major/minor. |
| SwiftLint 0.63.2 | Linting and style consistency | Add a minimal config; avoid noisy rule sets for a small app. |
| `swift-format` 602.0.0 | Deterministic formatting | Use via `swift format` in toolchain or Homebrew for pre-commit consistency. |
| XCTest / Swift Testing | Unit + integration tests | Focus tests on transformation safety and non-text clipboard no-op behavior. |

## Recommendation Confidence

| Decision | Confidence | Rationale |
|----------|------------|-----------|
| Native Swift/SwiftUI/AppKit stack | HIGH | Fully aligned with macOS-only requirement, smallest runtime overhead, strongest long-term compatibility. |
| `SMAppService` for startup behavior | HIGH | Apple explicitly positions it as the modern replacement path on macOS 13+. |
| `KeyboardShortcuts` for global hotkey | MEDIUM-HIGH | Actively maintained and widely used; adds dependency risk vs writing low-level hotkey handling yourself. |
| `LaunchAtLogin-Modern` helper | MEDIUM | Practical wrapper over modern APIs, but release cadence is slower than first-party frameworks. |
| Xcode 26.x as baseline toolchain | MEDIUM | Correct current generation, but point release may shift frequently. |

## Installation

```bash
# Core developer tools
xcode-select --install
brew install swiftlint swift-format

# Add package dependencies in Xcode (Package Dependencies UI):
# - https://github.com/sindresorhus/KeyboardShortcuts (2.4.0)
# - https://github.com/sindresorhus/LaunchAtLogin-Modern (1.1.0)

# Resolve deps in CI or locally once project/scheme exists
xcodebuild -resolvePackageDependencies -scheme <AppScheme>
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| SwiftUI `MenuBarExtra` | AppKit `NSStatusItem` | Use `NSStatusItem` if you must support macOS versions earlier than 13, or need highly custom AppKit-only status item behavior. |
| `KeyboardShortcuts` | Carbon-level custom hotkey handling | Use custom handling only if you need behavior not covered by the library and are willing to maintain low-level edge cases. |
| `LaunchAtLogin-Modern` | Direct `SMAppService` wiring in app code | Use direct API if you want zero third-party dependencies and can spend slightly more implementation effort. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Electron/Tauri for v1 | Adds unnecessary runtime/bundle overhead and extra bridge complexity for a tiny native menu-bar tool. | Native Swift + SwiftUI/AppKit |
| Legacy startup APIs (`SMLoginItemSetEnabled`) or manual `~/Library/LaunchAgents` installs on modern macOS | Apple documents `SMAppService` as the modern replacement path for macOS 13+. | `SMAppService` (or `LaunchAtLogin-Modern`) |
| Always-on clipboard mutation (transform every copy event by default) | Violates conservative/safe behavior goal and increases accidental text changes. | Manual menu action as default, optional explicit hotkey |
| Aggressive normalization in v1 (quote/style rewriting, semantic transforms) | High risk of altering intended user text, contrary to project constraints. | Minimal, deterministic cleanup only (trim edges + remove known problematic invisibles) |

## Stack Patterns by Variant

**If v1 remains personal-use and conservative (recommended):**
- Use menu-triggered cleanup by default.
- Add global hotkey as opt-in.
- Keep transforms deterministic and easy to disable.

**If backward compatibility with macOS <13 becomes required:**
- Replace `MenuBarExtra` with `NSStatusItem`-based AppKit menu bar implementation.
- Avoid `LaunchAtLogin-Modern`; implement older compatible startup handling.
- Expect extra QA for UI and login item behavior differences.

**If you later ship publicly:**
- Add telemetry-free diagnostics/logging and stricter error reporting.
- Keep hotkey unset by default; require explicit user setup.
- Consider notarization/release automation early.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| `MenuBarExtra` (SwiftUI) | macOS 13+ | API availability starts at macOS 13. |
| `SMAppService` | macOS 13+ | Modern login-item/service API on macOS 13 and later. |
| `LaunchAtLogin-Modern@1.1.0` | macOS 13+ | README explicitly targets macOS 13+. |
| `KeyboardShortcuts@2.4.0` | macOS 10.15+ | Works with SwiftUI and Cocoa; suitable for optional global hotkey. |
| `swift-format@602.0.0` | Swift 6 toolchain | Align formatter major with active SwiftSyntax/Swift toolchain generation. |
| `SwiftLint@0.63.2` | Current Xcode/Swift toolchains | Pin in CI to avoid drift across machines. |

## Sources

- https://www.swift.org/install/macos/ - verified current Swift stable line and release metadata
- https://docs.developer.apple.com/documentation/swiftui/menubarextra - verified menu-bar scene API and availability
- https://docs.developer.apple.com/documentation/appkit/nspasteboard - verified canonical clipboard API and behavior
- https://docs.developer.apple.com/documentation/servicemanagement/smappservice - verified modern login item/service API and replacements
- https://docs.developer.apple.com/documentation/appkit/nsstatusitem - verified AppKit alternative for older/macOS-specific menu bar handling
- https://github.com/sindresorhus/KeyboardShortcuts/releases/tag/2.4.0 - verified hotkey library current release
- https://github.com/sindresorhus/LaunchAtLogin-Modern/releases/tag/v1.1.0 - verified launch-at-login wrapper release
- https://github.com/sindresorhus/LaunchAtLogin-Modern - verified macOS 13+ requirement and usage pattern
- https://github.com/realm/SwiftLint/releases/tag/0.63.2 - verified lint tooling current release
- https://github.com/swiftlang/swift-format/releases/tag/602.0.0 - verified formatter current release
- https://github.com/swiftlang/swift-format - verified toolchain alignment guidance

---
*Stack research for: macOS clipboard utility*
*Researched: 2026-03-02*
