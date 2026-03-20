#!/bin/bash
set -e

APP_NAME="StayMemo"
BUILD_DIR=".build"
APP_BUNDLE="${APP_NAME}.app"

echo "Building ${APP_NAME}..."
swift build -c release

echo "Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/release/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Sources/StayMemo/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
cp "AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"

echo "Done: ${APP_BUNDLE}"
echo "Run with: open ${APP_BUNDLE}"
