# Quality Gates

All pull requests must satisfy the following before merge.

## Required Checks

1. `swift test` passes.
2. `make verify-phase3-hotkey-execution` passes.
3. No new safety denylist violations are introduced.
4. User-visible changes include tests and changelog updates.
5. If install/release scripts changed, shell syntax checks pass:
   - `bash -n scripts/install-app.sh`
   - `bash -n scripts/install-dev-app.sh`

## Safety Constraints

The project currently enforces denylist checks to prevent accidental introduction of:
- Network usage in cleanup paths
- Clipboard history persistence semantics
- Clipboard text disk persistence

Policy patterns are defined in `scripts/safety-denylist.txt` and validated by `scripts/verify-safety-constraints.sh`.
