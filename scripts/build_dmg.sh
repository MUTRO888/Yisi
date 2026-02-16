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

# Build Universal Binary (arm64 + x86_64)
echo "Building arm64..."
swift build -c release --arch arm64
ARM64_BIN="$(swift build -c release --arch arm64 --show-bin-path)/${APP_NAME}"

echo "Building x86_64..."
swift build -c release --arch x86_64
X86_BIN="$(swift build -c release --arch x86_64 --show-bin-path)/${APP_NAME}"

echo "Creating Universal Binary..."
lipo -create -output "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" "${ARM64_BIN}" "${X86_BIN}"
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

# Stage DMG contents (app + Applications symlink)
DMG_STAGE="${BUILD_DIR}/dmg_stage"
rm -rf "${DMG_STAGE}"
mkdir -p "${DMG_STAGE}"
cp -R "${APP_BUNDLE}" "${DMG_STAGE}/"
ln -s /Applications "${DMG_STAGE}/Applications"

# Package staged folder into DMG
hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${DMG_STAGE}" \
  -ov \
  -format UDZO \
  "${APP_NAME}.dmg"

echo "Build complete: ${APP_NAME}.dmg"
