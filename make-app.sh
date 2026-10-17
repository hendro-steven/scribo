#!/bin/bash
# Builds Scribo and assembles a runnable Scribo.app bundle (ad-hoc signed).
set -euo pipefail

CONFIG="${1:-release}"
APP_NAME="Scribo"
BUILD_DIR=".build/${CONFIG}"
APP_BUNDLE=".build/${APP_NAME}.app"

echo "▶ Building (${CONFIG})…"
swift build -c "${CONFIG}"

echo "▶ Assembling ${APP_BUNDLE}…"
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

echo "▶ Ad-hoc code signing…"
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "✅ Built ${APP_BUNDLE}"
echo "   Run it with:  open \"${APP_BUNDLE}\""
echo "   Look for the pencil icon in your menu bar, then press F9 to draw."
