#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${CLIPPOLISH_SMOKE_APP_PATH:-${CLIPPOLISH_APP_PATH:-$HOME/Applications/ClipPolish.app}}"
APP_EXECUTABLE="$APP_PATH/Contents/MacOS/ClipPolishApp"
BUNDLE_ID="${CLIPPOLISH_SMOKE_BUNDLE_ID:-com.clippolish.app}"
DEFAULT_SHORTCUT_DATA_HEX="7b22636172626f6e4b6579436f6465223a392c22636172626f6e4d6f64696669657273223a323831367d"

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/clip-polish-hotkey-smoke.XXXXXX")"
APP_PID=""
SKIPPED_SCENARIO=0

skip_env() {
  echo "SKIP:reason=$1"
  exit 0
}

fail() {
  echo "FAIL:$1" >&2
  exit 1
}

pass_scenario() {
  echo "PASS:scenario=$1"
}

scenario_skip() {
  echo "SKIP:scenario=$1 reason=$2"
  return 2
}

stop_app() {
  if [[ -n "${APP_PID:-}" ]] && kill -0 "$APP_PID" >/dev/null 2>&1; then
    kill "$APP_PID" >/dev/null 2>&1 || true
    wait "$APP_PID" 2>/dev/null || true
    APP_PID=""
  fi

  pkill -f "$APP_EXECUTABLE" >/dev/null 2>&1 || true
  sleep 1
}

cleanup() {
  stop_app
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

wait_for_log_pattern() {
  local log_path="$1"
  local pattern="$2"
  local attempts="${3:-60}"

  local i
  for ((i = 0; i < attempts; i++)); do
    if [[ -f "$log_path" ]] && rg -q -- "$pattern" "$log_path"; then
      return 0
    fi
    sleep 0.2
  done

  return 1
}

require_log_pattern() {
  local log_path="$1"
  local pattern="$2"
  local message="$3"

  if ! wait_for_log_pattern "$log_path" "$pattern"; then
    if [[ -f "$log_path" ]]; then
      cat "$log_path" >&2
    else
      echo "missing-log:$log_path" >&2
    fi
    fail "$message"
  fi
}

launch_app() {
  local log_path="$1"
  local permission_mode="${2:-live}"
  local app_stdout="$TMP_DIR/app-$(basename "$log_path").out"

  stop_app
  rm -f "$log_path"

  CLIPPOLISH_RUN_HOTKEY_E2E=1 \
  CLIPPOLISH_SMOKE_EVENT_LOG_PATH="$log_path" \
  CLIPPOLISH_SMOKE_PERMISSION_MODE="$permission_mode" \
  "$APP_EXECUTABLE" >"$app_stdout" 2>&1 &
  APP_PID=$!

  sleep 2
  if ! kill -0 "$APP_PID" >/dev/null 2>&1; then
    cat "$app_stdout" >&2 || true
    fail "app-launch-failed log=$app_stdout"
  fi
}

trigger_hotkey() {
  osascript -e 'tell application "System Events" to keystroke "v" using {command down, option down, shift down}' >/dev/null
}

configure_persisted_hotkey_defaults() {
  defaults write "$BUNDLE_ID" hotkey.enabled -bool true
  defaults write "$BUNDLE_ID" hotkey.shortcut -data "$DEFAULT_SHORTCUT_DATA_HEX"
}

seed_dirty_plain_text() {
  printf ' \u200BClipPolish Smoke \n' | pbcopy
}

seed_mixed_payload() {
  /usr/bin/swift <<'SWIFT'
import AppKit

let pasteboard = NSPasteboard.general
pasteboard.clearContents()

let item = NSPasteboardItem()
item.setString(" \u{200B}ClipPolish Smoke \n", forType: .string)
item.setString("{\\\\rtf1\\\\ansi ClipPolish Smoke}", forType: .rtf)
pasteboard.writeObjects([item])
SWIFT
}

pasteboard_snapshot_hash() {
  local snapshot
  snapshot="$(/usr/bin/swift <<'SWIFT'
import AppKit
import Foundation

let pasteboard = NSPasteboard.general
let itemSnapshots: [String] = (pasteboard.pasteboardItems ?? []).map { item in
  item.types
    .sorted(by: { $0.rawValue < $1.rawValue })
    .map { type in
      let data = item.data(forType: type) ?? Data()
      return "\(type.rawValue):\(data.base64EncodedString())"
    }
    .joined(separator: "|")
}

print(itemSnapshots.joined(separator: "||"))
SWIFT
)"
  printf '%s' "$snapshot" | shasum -a 256 | awk '{print $1}'
}

check_live_permission_or_skip() {
  local scenario="$1"
  local log_path="$2"

  if ! wait_for_log_pattern "$log_path" 'hotkey.permission=(granted|denied)'; then
    fail "scenario=$scenario missing permission result"
  fi

  if rg -q 'hotkey.permission=denied' "$log_path"; then
    scenario_skip "$scenario" "accessibility-permission-not-granted"
    return 2
  fi

  return 0
}

run_relaunch_scenario() {
  local scenario="relaunch"
  local launch_one_log="$TMP_DIR/relaunch-first.log"
  local launch_two_log="$TMP_DIR/relaunch-second.log"

  configure_persisted_hotkey_defaults

  seed_dirty_plain_text
  launch_app "$launch_one_log" "live"
  if ! trigger_hotkey; then
    scenario_skip "$scenario" "cannot-trigger-hotkey-via-system-events"
    return 2
  fi

  if ! check_live_permission_or_skip "$scenario" "$launch_one_log"; then
    return 2
  fi
  require_log_pattern "$launch_one_log" 'hotkey.cleanup=cleaned' "scenario=$scenario launch=1 expected cleanup=cleaned"
  require_log_pattern "$launch_one_log" 'hotkey.paste=posted' "scenario=$scenario launch=1 expected paste=posted"

  stop_app

  local enabled_value
  enabled_value="$(defaults read "$BUNDLE_ID" hotkey.enabled 2>/dev/null || true)"
  if [[ "$enabled_value" != "1" && "$enabled_value" != "true" ]]; then
    fail "scenario=$scenario persisted hotkey.enabled missing after relaunch"
  fi

  if ! defaults read "$BUNDLE_ID" hotkey.shortcut >/dev/null 2>&1; then
    fail "scenario=$scenario persisted hotkey.shortcut missing after relaunch"
  fi

  seed_dirty_plain_text
  launch_app "$launch_two_log" "live"
  if ! trigger_hotkey; then
    scenario_skip "$scenario" "cannot-trigger-hotkey-via-system-events-after-relaunch"
    return 2
  fi

  if ! check_live_permission_or_skip "$scenario" "$launch_two_log"; then
    return 2
  fi
  require_log_pattern "$launch_two_log" 'hotkey.cleanup=cleaned' "scenario=$scenario launch=2 expected cleanup=cleaned"
  require_log_pattern "$launch_two_log" 'hotkey.paste=posted' "scenario=$scenario launch=2 expected paste=posted"

  stop_app
  pass_scenario "$scenario"
}

run_permission_denied_scenario() {
  local scenario="permission-denied"
  local log_path="$TMP_DIR/permission-denied.log"

  seed_dirty_plain_text
  local before_text
  before_text="$(pbpaste)"

  launch_app "$log_path" "deny"
  if ! trigger_hotkey; then
    scenario_skip "$scenario" "cannot-trigger-hotkey-via-system-events"
    return 2
  fi

  require_log_pattern "$log_path" 'hotkey.permission=denied' "scenario=$scenario expected permission=denied"
  require_log_pattern "$log_path" 'hotkey.cleanup=skipped' "scenario=$scenario expected cleanup=skipped"
  require_log_pattern "$log_path" 'hotkey.paste=skipped' "scenario=$scenario expected paste=skipped"
  require_log_pattern "$log_path" 'hotkey.status=automationPermissionRequired' "scenario=$scenario expected permission guidance status"

  local after_text
  after_text="$(pbpaste)"
  if [[ "$after_text" != "$before_text" ]]; then
    fail "scenario=$scenario clipboard changed unexpectedly"
  fi

  stop_app
  pass_scenario "$scenario"
}

run_mixed_payload_scenario() {
  local scenario="mixed-payload"
  local log_path="$TMP_DIR/mixed-payload.log"

  seed_mixed_payload
  local before_hash
  before_hash="$(pasteboard_snapshot_hash)"

  launch_app "$log_path" "live"
  if ! trigger_hotkey; then
    scenario_skip "$scenario" "cannot-trigger-hotkey-via-system-events"
    return 2
  fi

  if ! check_live_permission_or_skip "$scenario" "$log_path"; then
    return 2
  fi
  require_log_pattern "$log_path" 'hotkey.cleanup=noPlainText' "scenario=$scenario expected cleanup=noPlainText"
  require_log_pattern "$log_path" 'hotkey.paste=skipped' "scenario=$scenario expected paste=skipped"

  local after_hash
  after_hash="$(pasteboard_snapshot_hash)"
  if [[ "$after_hash" != "$before_hash" ]]; then
    fail "scenario=$scenario mixed payload representations changed unexpectedly"
  fi

  stop_app
  pass_scenario "$scenario"
}

run_with_skip_handling() {
  local fn_name="$1"
  if "$fn_name"; then
    return 0
  fi

  local status=$?
  if [[ $status -eq 2 ]]; then
    SKIPPED_SCENARIO=1
    return 0
  fi

  exit $status
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  skip_env "non-macos-host"
fi

if ! launchctl print "gui/$(id -u)" >/dev/null 2>&1; then
  skip_env "no-aqua-session"
fi

if [[ "${CLIPPOLISH_RUN_HOTKEY_E2E:-0}" != "1" ]]; then
  skip_env "opt-in-required env=CLIPPOLISH_RUN_HOTKEY_E2E"
fi

if [[ ! -x "$APP_EXECUTABLE" ]]; then
  skip_env "missing-installed-app path=$APP_EXECUTABLE"
fi

if ! command -v rg >/dev/null 2>&1; then
  skip_env "missing-rg"
fi

UI_SCRIPTING_ENABLED="$(osascript -e 'tell application "System Events" to get UI elements enabled' 2>/dev/null || true)"
if [[ "$UI_SCRIPTING_ENABLED" != "true" ]]; then
  skip_env "system-events-ui-scripting-disabled"
fi

run_with_skip_handling run_permission_denied_scenario
run_with_skip_handling run_relaunch_scenario
run_with_skip_handling run_mixed_payload_scenario

if [[ "$SKIPPED_SCENARIO" -eq 1 ]]; then
  echo "SKIP:one-or-more-scenarios-skipped"
  exit 0
fi

echo "PASS:hotkey-smoke scenarios=3"
