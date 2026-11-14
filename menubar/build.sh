#!/bin/bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$HOME/Applications/Lidocaine.app"
TMP_BIN="$(mktemp -d)/LidocaineBar"

WORK="$(dirname "$TMP_BIN")"
swiftc -O -swift-version 5 -framework Cocoa "$SRC_DIR/Icons.swift" "$SRC_DIR/main.swift" -o "$TMP_BIN"
swiftc -O -swift-version 5 -framework Cocoa "$SRC_DIR/Icons.swift" "$SRC_DIR/tools/main.swift" -o "$WORK/render"
CLAUDE_ICNS="/Applications/Claude.app/Contents/Resources/electron.icns"
if [ -f "$CLAUDE_ICNS" ]; then
  iconutil -c iconset "$CLAUDE_ICNS" -o "$WORK/claude.iconset"
  "$WORK/render" spark-mask "$WORK/claude-spark.png" "$WORK/claude.iconset/icon_512x512@2x.png"
  export LIDOCAINE_SPARK="$WORK/claude-spark.png"
fi
mkdir -p "$WORK/Lidocaine.iconset"
"$WORK/render" iconset "$WORK/Lidocaine.iconset"
iconutil -c icns "$WORK/Lidocaine.iconset" -o "$WORK/Lidocaine.icns"

pkill -x LidocaineBar 2>/dev/null || true
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mv "$TMP_BIN" "$APP/Contents/MacOS/LidocaineBar"
mkdir -p "$APP/Contents/Resources"
cp "$WORK/Lidocaine.icns" "$APP/Contents/Resources/Lidocaine.icns"
[ -f "$WORK/claude-spark.png" ] && cp "$WORK/claude-spark.png" "$APP/Contents/Resources/claude-spark.png"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key><string>io.github.artemkorchunov.lidocaine</string>
  <key>CFBundleName</key><string>Lidocaine</string>
  <key>CFBundleDisplayName</key><string>Lidocaine</string>
  <key>CFBundleExecutable</key><string>LidocaineBar</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleIconFile</key><string>Lidocaine</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

# Which commit this app was built from, so "lidocaine update" can tell when the
# app is behind the code (for example after an update that died before rebuilding).
git -C "$SRC_DIR" rev-parse HEAD > "$APP/Contents/Resources/built-from" 2>/dev/null || true
codesign --force --sign - "$APP" >/dev/null
touch "$APP"
# Moves an install from before the rename (Insomnia) over, so the app finds its command.
/bin/bash "$SRC_DIR/../scripts/lidocaine.sh" migrate || true
open "$APP"
echo "Built and launched $APP"
