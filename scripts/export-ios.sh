#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
PRESET="${IOS_PRESET:-iOS Device Debug}"
OUT_DIR="${1:-$ROOT_DIR/build/ios}"
PROJECT_PATH="$OUT_DIR/LiuziChong.xcodeproj"

mkdir -p "$OUT_DIR"
printf 'Exporting %s to %s\n' "$PRESET" "$PROJECT_PATH"
"$GODOT_BIN" --headless --path "$ROOT_DIR/godot" --export-debug "$PRESET" "$PROJECT_PATH"

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "Godot did not create an Xcode project at $PROJECT_PATH" >&2
  exit 1
fi

xcodebuild -list -project "$PROJECT_PATH"
printf '\nXcode project ready: %s\n' "$PROJECT_PATH"
printf 'Open it in Xcode, choose your Apple Team, then run on a device or simulator.\n'
