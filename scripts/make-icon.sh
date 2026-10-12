#!/bin/bash
# Redraws the app icon and writes Resources/AppIcon.icns (plus docs/images/icon.png for the README).
set -euo pipefail
cd "$(dirname "$0")/.."

ICONSET="build/AppIcon.iconset"
rm -rf "$ICONSET"
swift run IconRenderer "$ICONSET"
mkdir -p Resources
iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
cp "$ICONSET/icon_256x256@2x.png" docs/images/icon.png
echo "Wrote Resources/AppIcon.icns"
