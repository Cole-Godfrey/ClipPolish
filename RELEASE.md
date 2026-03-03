# Release Process

This document describes the release process for ClipPolish.

## 1. Prepare Release Candidate

1. Ensure working tree is clean.
2. Run validation:

```bash
swift test
make verify-phase3-hotkey-execution
```

3. Update release metadata:
- `ClipPolishApp/Info.plist` (`CFBundleShortVersionString`, `CFBundleVersion`)
- `CHANGELOG.md` (`[Unreleased]` -> new version section)

## 2. Create Tag

```bash
git checkout <release-branch>
git pull --ff-only origin <release-branch>
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin <release-branch>
git push origin vX.Y.Z
```

## 3. Publish GitHub Release

1. Create a GitHub Release from tag `vX.Y.Z`.
2. Paste release notes from the corresponding `CHANGELOG.md` section.
3. Attach build artifacts if distributing binaries.

## 4. Build Installer Artifact

Use the installer pipeline to create a `.pkg` that installs `ClipPolish.app` into `/Applications`:

```bash
make build-release-installer
```

Optional signing env vars:

- `CLIPPOLISH_APP_SIGN_IDENTITY` for app bundle signing (Developer ID Application).
- `CLIPPOLISH_PKG_SIGN_IDENTITY` for installer signing (Developer ID Installer).

Output: `dist/ClipPolish-<version>.pkg`

GitHub releases can attach this artifact automatically via `.github/workflows/release-installer.yml`.

Installer behavior:

- Installs app into `/Applications`.
- Opens the macOS Accessibility pane after install.
- Shows a prompt reminding the user to enable ClipPolish manually.

Note: macOS does not allow normal third-party installers to auto-enable Accessibility permission.

## 5. (Optional) Notarize Installer

If shipping signed release artifacts, notarize your installer package:

1. Submit for notarization:

```bash
xcrun notarytool submit /path/to/ClipPolish.pkg \
  --keychain-profile "<notary-profile>" \
  --wait
```

2. Staple ticket:

```bash
xcrun stapler staple /path/to/ClipPolish.pkg
```

3. Verify:

```bash
spctl --assess --type install --verbose=4 /path/to/ClipPolish.pkg
pkgutil --check-signature /path/to/ClipPolish.pkg
```

## 6. Post-Release

- Move next changes into `Unreleased` in `CHANGELOG.md`.
- Bump internal build version if needed.
