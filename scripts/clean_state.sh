#!/bin/bash
set -e

BUNDLE_ID="com.sonianmu.yisi"
APP_NAME="Yisi"

echo "Removing all traces of ${APP_NAME}..."

# 1. Quit running instances
osascript -e "tell application \"${APP_NAME}\" to quit" 2>/dev/null || true
pkill -f "${APP_NAME}.app" 2>/dev/null || true
sleep 1

# 2. Unregister login item
launchctl bootout gui/$(id -u) "com.apple.xpc.launchd.user.${BUNDLE_ID}" 2>/dev/null || true

# 3. Remove application
for app_path in \
    "/Applications/${APP_NAME}.app" \
    "$HOME/Applications/${APP_NAME}.app" \
    "$HOME/Desktop/${APP_NAME}.app" \
    "$HOME/Downloads/${APP_NAME}.app"; do
    if [ -e "$app_path" ]; then
        echo "  removing $app_path"
        rm -rf "$app_path"
    fi
done

# 4. Remove Application Support
for dir in \
    "$HOME/Library/Application Support/${BUNDLE_ID}" \
    "$HOME/Library/Application Support/${APP_NAME}" \
    "$HOME/Library/Application Support/com.yisi.app"; do
    if [ -d "$dir" ]; then
        echo "  removing $dir"
        rm -rf "$dir"
    fi
done

# 5. Remove Preferences
if [ -f "$HOME/Library/Preferences/${BUNDLE_ID}.plist" ]; then
    echo "  removing Preferences plist"
    rm -f "$HOME/Library/Preferences/${BUNDLE_ID}.plist"
fi
defaults delete "$BUNDLE_ID" 2>/dev/null || true

# 6. Remove Caches & HTTP Storage
for dir in \
    "$HOME/Library/Caches/${BUNDLE_ID}" \
    "$HOME/Library/HTTPStorages/${BUNDLE_ID}"; do
    if [ -d "$dir" ]; then
        echo "  removing $dir"
        rm -rf "$dir"
    fi
done

# 7. Remove Saved State
if [ -d "$HOME/Library/Saved Application State/${BUNDLE_ID}.savedState" ]; then
    echo "  removing Saved Application State"
    rm -rf "$HOME/Library/Saved Application State/${BUNDLE_ID}.savedState"
fi

# 8. Remove Sandbox Containers
for dir in \
    "$HOME/Library/Containers/${BUNDLE_ID}" \
    "$HOME/Library/Group Containers/group.${BUNDLE_ID}"; do
    if [ -d "$dir" ]; then
        echo "  removing $dir"
        rm -rf "$dir"
    fi
done

# 9. Remove history database
if [ -f "$HOME/Documents/YisiHistory.sqlite" ]; then
    echo "  removing Documents/YisiHistory.sqlite"
    rm -f "$HOME/Documents/YisiHistory.sqlite"
    rm -f "$HOME/Documents/YisiHistory.sqlite-wal"
    rm -f "$HOME/Documents/YisiHistory.sqlite-shm"
fi

# 10. Reset TCC permissions (Accessibility, Input Monitoring, Key Events)
echo "  resetting TCC permissions"
tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null || true
tccutil reset ListenEvent "$BUNDLE_ID" 2>/dev/null || true
tccutil reset PostEvent "$BUNDLE_ID" 2>/dev/null || true
tccutil reset ScreenCapture "$BUNDLE_ID" 2>/dev/null || true

# 11. Remove DMG artifacts (not source code)
rm -f "${0%/*}/../${APP_NAME}.dmg"

echo "Done. All traces of ${APP_NAME} removed."
