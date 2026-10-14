#!/bin/bash
# Builds "Am I Artificially Intelligent.app" into build/ (release, ad-hoc signed).
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Am I Artificially Intelligent"
APP="build/$APP_NAME.app"

swift build -c release --product AmIArtificiallyIntelligent
BIN="$(swift build -c release --show-bin-path)/AmIArtificiallyIntelligent"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/AmIArtificiallyIntelligent"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleDisplayName</key><string>Am I Artificially Intelligent?</string>
    <key>CFBundleIdentifier</key><string>com.amalmehta.AmIArtificiallyIntelligent</string>
    <key>CFBundleExecutable</key><string>AmIArtificiallyIntelligent</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.entertainment</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Built: $APP"
