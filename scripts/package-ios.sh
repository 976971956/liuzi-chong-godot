#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/ios/LiuziChong.xcodeproj"
TEAM_ID="${IOS_TEAM_ID:-BYSMY792J7}"
SIGNING_IDENTITY="${IOS_SIGNING_IDENTITY:-Apple Development}"
CONFIGURATION="${IOS_CONFIGURATION:-Debug}"
IOS_PRESET="${IOS_PRESET:-iOS Device Debug}"
OUT_DIR="${1:-$ROOT_DIR/build/ios}"
ARCHIVE_PATH="$OUT_DIR/LiuziChong.xcarchive"
IPA_DIR="$OUT_DIR/ipa"
EXPORT_OPTIONS="$OUT_DIR/export_options.generated.plist"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is required. Install Xcode and select it with xcode-select." >&2
  exit 1
fi

if [[ -z "${GODOT_BIN:-}" ]]; then
  if command -v godot >/dev/null 2>&1; then
    GODOT_BIN="$(command -v godot)"
  elif [[ -x /opt/homebrew/bin/godot ]]; then
    GODOT_BIN="/opt/homebrew/bin/godot"
  elif [[ -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then
    GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
  else
    echo "Godot 4 is required to refresh the iOS game data pack." >&2
    exit 1
  fi
fi

mkdir -p "$OUT_DIR"
rm -rf "$ARCHIVE_PATH" "$IPA_DIR"

echo "Exporting latest Godot data pack"
GODOT_USER_DIR="$OUT_DIR/godot-user" "$GODOT_BIN" \
  --headless \
  --path "$ROOT_DIR/godot" \
  --export-pack "$IOS_PRESET" \
  "$ROOT_DIR/ios/LiuziChong.pck"

echo "Archiving iOS app for team $TEAM_ID"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme LiuziChong \
  -configuration "$CONFIGURATION" \
  -sdk iphoneos \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
  archive

cat > "$EXPORT_OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>development</string>
  <key>destination</key>
  <string>export</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>$TEAM_ID</string>
  <key>compileBitcode</key>
  <false/>
  <key>stripSwiftSymbols</key>
  <true/>
</dict>
</plist>
PLIST

echo "Exporting IPA"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -exportPath "$IPA_DIR" \
  -allowProvisioningUpdates

echo
echo "IPA ready: $IPA_DIR/LiuziChong.ipa"
