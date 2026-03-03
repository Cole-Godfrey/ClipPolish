#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="debug"
RUN_APP="yes"

for arg in "$@"; do
  case "$arg" in
    debug|release)
      CONFIG="$arg"
      ;;
    --no-run)
      RUN_APP="no"
      ;;
    *)
      echo "Usage: bash scripts/install-dev-app.sh [debug|release] [--no-run]" >&2
      exit 1
      ;;
  esac
done

APP_PATH="${CLIPPOLISH_DEV_APP_PATH:-$HOME/Applications/ClipPolish Dev.app}"
BUNDLE_ID="${CLIPPOLISH_DEV_BUNDLE_ID:-com.clippolish.dev}"
APP_VERSION="${CLIPPOLISH_DEV_APP_VERSION:-1.0.0}"
BUILD_VERSION="${CLIPPOLISH_DEV_BUILD_VERSION:-1}"

cd "$ROOT"
swift build -c "$CONFIG"

BIN_ARCH="$ROOT/.build/arm64-apple-macosx/$CONFIG/ClipPolishApp"
BIN_GENERIC="$ROOT/.build/$CONFIG/ClipPolishApp"
if [[ -x "$BIN_ARCH" ]]; then
  BIN_PATH="$BIN_ARCH"
elif [[ -x "$BIN_GENERIC" ]]; then
  BIN_PATH="$BIN_GENERIC"
else
  echo "Could not find built executable for config '$CONFIG'." >&2
  exit 1
fi

mkdir -p "$(dirname "$APP_PATH")" "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"

cat > "$APP_PATH/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>ClipPolishApp</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>ClipPolish Dev</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${APP_VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${BUILD_VERSION}</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.productivity</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST

cp "$BIN_PATH" "$APP_PATH/Contents/MacOS/ClipPolishApp"
chmod +x "$APP_PATH/Contents/MacOS/ClipPolishApp"

# Ad-hoc sign so macOS treats this as an app bundle consistently.
codesign --force --deep --sign - "$APP_PATH" >/dev/null 2>&1 || true

echo "Installed: $APP_PATH"
echo "Executable: $APP_PATH/Contents/MacOS/ClipPolishApp"

if [[ "$RUN_APP" == "yes" ]]; then
  open "$APP_PATH"
fi
