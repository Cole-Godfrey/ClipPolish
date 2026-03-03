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

## 4. (Optional) Signed and Notarized macOS App Build

If shipping `.app` artifacts, use this high-level sequence:

1. Build release app bundle.
2. Sign with Developer ID Application certificate:

```bash
codesign --deep --force --options runtime \
  --sign "Developer ID Application: <Team or Name>" \
  /path/to/ClipPolish.app
```

3. Submit for notarization:

```bash
xcrun notarytool submit /path/to/ClipPolish.zip \
  --keychain-profile "<notary-profile>" \
  --wait
```

4. Staple ticket:

```bash
xcrun stapler staple /path/to/ClipPolish.app
```

5. Verify:

```bash
spctl --assess --verbose=4 /path/to/ClipPolish.app
codesign --verify --deep --strict --verbose=2 /path/to/ClipPolish.app
```

## 5. Post-Release

- Move next changes into `Unreleased` in `CHANGELOG.md`.
- Bump internal build version if needed.
