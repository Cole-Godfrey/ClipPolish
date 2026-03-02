#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DENYLIST="${SCRIPT_DIR}/safety-denylist.txt"
TARGETS=(
  "${REPO_ROOT}/Sources/ClipPolishCore"
  "${REPO_ROOT}/Sources/ClipPolishApp"
)

if ! command -v rg >/dev/null 2>&1; then
  echo "error: ripgrep (rg) is required to run safety checks" >&2
  exit 2
fi

if [[ ! -f "${DENYLIST}" ]]; then
  echo "error: denylist file not found at ${DENYLIST}" >&2
  exit 2
fi

violation_count=0

while IFS=$'\t' read -r rule_id pattern reason; do
  if [[ -z "${rule_id}" || "${rule_id}" == \#* ]]; then
    continue
  fi

  for target in "${TARGETS[@]}"; do
    if [[ ! -d "${target}" ]]; then
      continue
    fi

    set +e
    matches="$(rg --line-number --glob '*.swift' --no-heading -e "${pattern}" "${target}" 2>&1)"
    rg_status=$?
    set -e

    if [[ "${rg_status}" -eq 2 ]]; then
      echo "error: invalid regex in ${DENYLIST} for rule ${rule_id}: ${pattern}" >&2
      echo "${matches}" >&2
      exit 2
    fi

    if [[ "${rg_status}" -eq 0 ]]; then
      violation_count=$((violation_count + 1))
      echo "violation: ${rule_id}"
      echo "reason: ${reason}"
      echo "scope: ${target#${REPO_ROOT}/}"
      echo "${matches}"
      echo
    fi
  done
done < "${DENYLIST}"

if [[ "${violation_count}" -gt 0 ]]; then
  echo "safety verification failed: ${violation_count} violation(s) detected."
  exit 1
fi

echo "safety verification passed: no network or clipboard-history persistence patterns detected."
