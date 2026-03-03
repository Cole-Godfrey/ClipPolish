#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFO_PLIST="$ROOT/ClipPolishApp/Info.plist"
OUTPUT_DIR="${CLIPPOLISH_OUTPUT_DIR:-$ROOT/dist}"
APP_NAME="${CLIPPOLISH_APP_NAME:-ClipPolish.app}"
PKG_IDENTIFIER="${CLIPPOLISH_PKG_IDENTIFIER:-com.clippolish.installer}"
APP_SIGN_IDENTITY="${CLIPPOLISH_APP_SIGN_IDENTITY:-}"
PKG_SIGN_IDENTITY="${CLIPPOLISH_PKG_SIGN_IDENTITY:-}"

VERSION="${1:-}"
BUILD_NUMBER="${2:-}"

if [[ -z "$VERSION" ]]; then
  VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")"
fi

if [[ -z "$BUILD_NUMBER" ]]; then
  BUILD_NUMBER="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST")"
fi

RELEASE_BINARY_ARCH="$ROOT/.build/arm64-apple-macosx/release/ClipPolishApp"
RELEASE_BINARY_GENERIC="$ROOT/.build/release/ClipPolishApp"

mkdir -p "$ROOT/.build"
WORK_DIR="$(mktemp -d "$ROOT/.build/release-installer.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Building release binary..."
cd "$ROOT"
swift build -c release

if [[ -x "$RELEASE_BINARY_ARCH" ]]; then
  RELEASE_BINARY="$RELEASE_BINARY_ARCH"
elif [[ -x "$RELEASE_BINARY_GENERIC" ]]; then
  RELEASE_BINARY="$RELEASE_BINARY_GENERIC"
else
  echo "Could not find release binary after build." >&2
  exit 1
fi

STAGING_ROOT="$WORK_DIR/root"
APP_PATH="$STAGING_ROOT/Applications/$APP_NAME"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"

cp "$INFO_PLIST" "$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable ClipPolishApp" "$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP_PATH/Contents/Info.plist"

cp "$RELEASE_BINARY" "$APP_PATH/Contents/MacOS/ClipPolishApp"
chmod +x "$APP_PATH/Contents/MacOS/ClipPolishApp"

if [[ -n "$APP_SIGN_IDENTITY" ]]; then
  echo "Signing app bundle with identity: $APP_SIGN_IDENTITY"
  codesign --force --deep --options runtime --timestamp --sign "$APP_SIGN_IDENTITY" "$APP_PATH"
else
  echo "Ad-hoc signing app bundle (set CLIPPOLISH_APP_SIGN_IDENTITY for release signing)."
  codesign --force --deep --sign - "$APP_PATH"
fi

mkdir -p "$OUTPUT_DIR"
PKG_OUTPUT_PATH="$OUTPUT_DIR/ClipPolish-$VERSION.pkg"
rm -f "$PKG_OUTPUT_PATH"

PKGBUILD_ARGS=(
  --root "$STAGING_ROOT"
  --identifier "$PKG_IDENTIFIER"
  --version "$VERSION"
  --install-location "/"
  --scripts "$ROOT/packaging/macos/scripts"
  "$PKG_OUTPUT_PATH"
)

if [[ -n "$PKG_SIGN_IDENTITY" ]]; then
  echo "Signing installer package with identity: $PKG_SIGN_IDENTITY"
  PKGBUILD_ARGS=(--sign "$PKG_SIGN_IDENTITY" "${PKGBUILD_ARGS[@]}")
else
  echo "Building unsigned installer package (set CLIPPOLISH_PKG_SIGN_IDENTITY for release signing)."
fi

pkgbuild "${PKGBUILD_ARGS[@]}"

echo
echo "Installer ready: $PKG_OUTPUT_PATH"
echo "Bundle version: $VERSION ($BUILD_NUMBER)"
echo "Note: macOS requires users to manually enable Accessibility."
echo "The installer opens the Accessibility pane after installation."
