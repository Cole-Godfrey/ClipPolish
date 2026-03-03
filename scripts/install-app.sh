#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFO_PLIST="$ROOT/ClipPolishApp/Info.plist"

CONFIG="release"
RUN_APP="yes"
DEFAULT_USER_APP_PATH="$HOME/Applications/ClipPolish.app"

APP_PATH="${CLIPPOLISH_APP_PATH:-$DEFAULT_USER_APP_PATH}"
BUNDLE_ID="${CLIPPOLISH_BUNDLE_ID:-com.clippolish.app}"
APP_DISPLAY_NAME="${CLIPPOLISH_APP_DISPLAY_NAME:-ClipPolish}"
APP_VERSION="${CLIPPOLISH_APP_VERSION:-}"
BUILD_VERSION="${CLIPPOLISH_BUILD_VERSION:-}"

for arg in "$@"; do
  case "$arg" in
    debug|release)
      CONFIG="$arg"
      ;;
    --no-run)
      RUN_APP="no"
      ;;
    --system-applications)
      APP_PATH="/Applications/ClipPolish.app"
      ;;
    --user-applications)
      APP_PATH="$DEFAULT_USER_APP_PATH"
      ;;
    *)
      echo "Usage: bash scripts/install-app.sh [debug|release] [--no-run] [--system-applications|--user-applications]" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$APP_VERSION" ]]; then
  APP_VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null || echo "1.0.1")"
fi

if [[ -z "$BUILD_VERSION" ]]; then
  BUILD_VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST" 2>/dev/null || echo "1")"
fi

APP_PARENT_DIR="$(dirname "$APP_PATH")"
if [[ "$APP_PARENT_DIR" == "/Applications" && ! -w "$APP_PARENT_DIR" ]]; then
  echo "Cannot write to $APP_PARENT_DIR without elevated permissions." >&2
  echo "Run with sudo or omit --system-applications to install into $DEFAULT_USER_APP_PATH." >&2
  exit 1
fi

INSTALL_ARGS=("$CONFIG")
if [[ "$RUN_APP" == "no" ]]; then
  INSTALL_ARGS+=("--no-run")
fi

CLIPPOLISH_DEV_APP_PATH="$APP_PATH" \
CLIPPOLISH_DEV_BUNDLE_ID="$BUNDLE_ID" \
CLIPPOLISH_DEV_APP_DISPLAY_NAME="$APP_DISPLAY_NAME" \
CLIPPOLISH_DEV_APP_VERSION="$APP_VERSION" \
CLIPPOLISH_DEV_BUILD_VERSION="$BUILD_VERSION" \
bash "$ROOT/scripts/install-dev-app.sh" "${INSTALL_ARGS[@]}"

echo
echo "ClipPolish setup complete."
echo "Installed app: $APP_PATH"
echo "If hotkey paste is blocked, enable Accessibility:"
echo "System Settings -> Privacy & Security -> Accessibility"
