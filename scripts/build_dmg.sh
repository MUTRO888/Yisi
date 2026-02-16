#!/bin/bash
set -e

APP_NAME="Yisi"
BUNDLE_ID="com.sonianmu.yisi"
VERSION="${VERSION:-1.0.0}"
BUILD_DIR=".build_app"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

# Clean previous build artifacts
rm -rf "${BUILD_DIR}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# === Icon Generation Phase ===
echo "Generating app icon..."
swift scripts/generate_icon.swift
if [ ! -f "icon_1024x1024.png" ]; then
  echo "ERROR: icon_1024x1024.png not found. Aborting."
  exit 1
fi

mkdir -p AppIcon.iconset
sips -z 16 16     icon_1024x1024.png --out AppIcon.iconset/icon_16x16.png
sips -z 32 32     icon_1024x1024.png --out AppIcon.iconset/icon_16x16@2x.png
sips -z 32 32     icon_1024x1024.png --out AppIcon.iconset/icon_32x32.png
sips -z 64 64     icon_1024x1024.png --out AppIcon.iconset/icon_32x32@2x.png
sips -z 128 128   icon_1024x1024.png --out AppIcon.iconset/icon_128x128.png
sips -z 256 256   icon_1024x1024.png --out AppIcon.iconset/icon_128x128@2x.png
sips -z 256 256   icon_1024x1024.png --out AppIcon.iconset/icon_256x256.png
sips -z 512 512   icon_1024x1024.png --out AppIcon.iconset/icon_256x256@2x.png
sips -z 512 512   icon_1024x1024.png --out AppIcon.iconset/icon_512x512.png
cp icon_1024x1024.png AppIcon.iconset/icon_512x512@2x.png

iconutil -c icns AppIcon.iconset -o AppIcon.icns
cp AppIcon.icns "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"

# Cleanup icon build artifacts
rm -rf AppIcon.iconset icon_1024x1024.png AppIcon.icns
echo "App icon generated successfully."

# Build release binary via SPM
swift build -c release

# Locate binary and copy into .app bundle
BIN_PATH=$(swift build -c release --show-bin-path)
cp "${BIN_PATH}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Generate Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
PLIST

# Package .app into DMG
hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${APP_BUNDLE}" \
  -ov \
  -format UDZO \
  "${APP_NAME}.dmg"

echo "Build complete: ${APP_NAME}.dmg"
