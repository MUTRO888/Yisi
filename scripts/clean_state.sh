#!/bin/bash

echo "🧹 Cleaning up Yisi installation and state..."

# 1. Remove the Application
if [ -d "/Applications/Yisi.app" ]; then
    echo "removing /Applications/Yisi.app"
    rm -rf /Applications/Yisi.app
fi

# 2. Remove Application Support data
if [ -d "$HOME/Library/Application Support/com.sonianmu.yisi" ]; then
    echo "removing Application Support/com.sonianmu.yisi"
    rm -rf "$HOME/Library/Application Support/com.sonianmu.yisi"
fi
if [ -d "$HOME/Library/Application Support/Yisi" ]; then
    echo "removing Application Support/Yisi"
    rm -rf "$HOME/Library/Application Support/Yisi"
fi

# 3. Remove Preferences
if [ -f "$HOME/Library/Preferences/com.sonianmu.yisi.plist" ]; then
    echo "removing Preferences"
    rm -f "$HOME/Library/Preferences/com.sonianmu.yisi.plist"
fi
defaults delete com.sonianmu.yisi 2>/dev/null || true

# 4. Remove Caches
if [ -d "$HOME/Library/Caches/com.sonianmu.yisi" ]; then
    echo "removing Caches"
    rm -rf "$HOME/Library/Caches/com.sonianmu.yisi"
fi
if [ -d "$HOME/Library/HTTPStorages/com.sonianmu.yisi" ]; then
    echo "removing HTTPStorages"
    rm -rf "$HOME/Library/HTTPStorages/com.sonianmu.yisi"
fi

# 5. Remove Saved State
if [ -d "$HOME/Library/Saved Application State/com.sonianmu.yisi.savedState" ]; then
    echo "removing Saved Application State"
    rm -rf "$HOME/Library/Saved Application State/com.sonianmu.yisi.savedState"
fi

# 6. Remove Sandbox Containers
if [ -d "$HOME/Library/Containers/com.sonianmu.yisi" ]; then
    echo "removing Containers"
    rm -rf "$HOME/Library/Containers/com.sonianmu.yisi"
fi
if [ -d "$HOME/Library/Group Containers/group.com.sonianmu.yisi" ]; then
    echo "removing Group Containers"
    rm -rf "$HOME/Library/Group Containers/group.com.sonianmu.yisi"
fi

echo "✨ All traces of Yisi have been removed from your system."
