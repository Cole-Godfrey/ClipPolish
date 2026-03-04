## Summary

Describe what changed and why.

## Type of change

- [ ] Bug fix
- [ ] Feature
- [ ] Refactor
- [ ] Documentation
- [ ] CI/Build

## Validation

- [ ] `swift test`
- [ ] `make verify-phase7-hotkey-e2e`
- [ ] Optional smoke run when host supports it: `CLIPPOLISH_RUN_HOTKEY_E2E=1 make verify-phase7-hotkey-smoke` (or documented `SKIP:` reason)
- [ ] Added/updated tests for behavior changes
- [ ] If install/release scripts changed: `bash -n scripts/install-app.sh`, `bash -n scripts/install-dev-app.sh`

## Checklist

- [ ] Updated docs if behavior changed
- [ ] Updated `CHANGELOG.md` for user-visible changes
- [ ] Confirmed no network/history persistence behavior added to cleanup flow
