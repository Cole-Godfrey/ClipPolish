# Release Process

This document describes the release process for ClipPolish.

## 1. Prepare Release Candidate

1. Ensure working tree is clean.
2. Run validation:

```bash
swift test
make verify-phase7-hotkey-e2e
```

Optional process smoke verification (host-dependent):

```bash
CLIPPOLISH_RUN_HOTKEY_E2E=1 make verify-phase7-hotkey-smoke
```

`SKIP:` output from the smoke harness is acceptable when the release environment lacks required GUI/session capabilities.

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
3. Confirm the release notes include source install instructions (`bash scripts/install-app.sh`).

## 4. Validate Source Install Flow

From a clean checkout of the release tag, verify the recommended install flow:

```bash
bash scripts/install-app.sh --no-run
```

Expected output app bundle:

- `~/Applications/ClipPolish.app` (default)
- `/Applications/ClipPolish.app` when using `--system-applications`

## 5. Post-Release

- Move next changes into `Unreleased` in `CHANGELOG.md`.
- Bump internal build version if needed.
