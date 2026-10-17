#!/bin/bash
# Builds Scribo and assembles a runnable, ad-hoc-signed Scribo.app bundle.
#
# Usage:
#   ./make-app.sh                 # release build for the host arch
#   ./make-app.sh --universal     # universal (arm64 + x86_64) build
#   ./make-app.sh --zip           # also produce a distributable Scribo.zip
#   ./make-app.sh --debug         # debug build
# Flags combine, e.g.  ./make-app.sh --universal --zip
set -euo pipefail

CONFIG="release"
UNIVERSAL=0
ZIP=0
for arg in "$@"; do
  case "$arg" in
    --debug)     CONFIG="debug" ;;
    --universal) UNIVERSAL=1 ;;
    --zip)       ZIP=1 ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

APP_NAME="Scribo"

# Determine the version to stamp into the bundle (leading "v" stripped):
#   1. explicit SCRIBO_VERSION env (the release workflow sets it from the tag)
#   2. the most recent git tag reachable from HEAD
#   3. empty -> keep whatever Info.plist already declares
if [ -n "${SCRIBO_VERSION:-}" ]; then
  VERSION="${SCRIBO_VERSION#v}"
elif VERSION_TAG="$(git describe --tags --abbrev=0 2>/dev/null)"; then
  VERSION="${VERSION_TAG#v}"
else
  VERSION=""
fi

BUILD_ARGS=(-c "$CONFIG")
LABEL="${CONFIG}"
if [ "$UNIVERSAL" -eq 1 ]; then
  BUILD_ARGS+=(--arch arm64 --arch x86_64)
  LABEL="${CONFIG}, universal"
fi

echo "▶ Building ${APP_NAME} (${LABEL})…"
swift build "${BUILD_ARGS[@]}"
BIN_DIR="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"

APP_BUNDLE=".build/${APP_NAME}.app"
echo "▶ Assembling ${APP_BUNDLE}…"
rm -rf "$APP_BUNDLE"
mkdir -p "${APP_BUNDLE}/Contents/MacOS" "${APP_BUNDLE}/Contents/Resources"
cp "${BIN_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
if [ -f "Resources/Scribo.icns" ]; then
  cp "Resources/Scribo.icns" "${APP_BUNDLE}/Contents/Resources/Scribo.icns"
fi

if [ -n "${VERSION}" ]; then
  echo "▶ Stamping version ${VERSION}…"
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" \
    "${APP_BUNDLE}/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${VERSION}" \
    "${APP_BUNDLE}/Contents/Info.plist"
fi

echo "▶ Ad-hoc code signing…"
codesign --force --deep --sign - "${APP_BUNDLE}"

if [ "$ZIP" -eq 1 ]; then
  echo "▶ Zipping…"
  rm -f "${APP_NAME}.zip"
  # ditto preserves bundle structure / symlinks / metadata (unlike plain zip).
  ditto -c -k --keepParent "${APP_BUNDLE}" "${APP_NAME}.zip"
  echo "✅ Created ${APP_NAME}.zip"
fi

echo "✅ Built ${APP_BUNDLE}"
echo "   Run it:  open \"${APP_BUNDLE}\""
