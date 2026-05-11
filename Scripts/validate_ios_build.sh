#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DEVELOPER_DIR_PATH="$(xcode-select -p 2>/dev/null || true)"
echo "Developer directory: ${DEVELOPER_DIR_PATH:-unknown}"
if [[ "$DEVELOPER_DIR_PATH" == *CommandLineTools* ]]; then
  echo "Full Xcode is required for iOS Simulator validation." >&2
  echo "Select it with: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  exit 1
fi

xcodebuild -version
xcrun --sdk iphonesimulator --show-sdk-path >/dev/null
swift test

DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/DerivedData/ValidateIOS}"
rm -rf "$DERIVED_DATA_PATH"

xcodebuild \
  -project MiniDiablo.xcodeproj \
  -scheme MiniDiablo \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/MiniDiablo.app"
test -d "$APP_PATH"

SIMULATOR_ID="$(
  xcrun simctl list devices available -j | python3.12 -c 'import json, sys
data = json.load(sys.stdin)
for devices in data.get("devices", {}).values():
    for device in devices:
        if device.get("isAvailable") and "iPhone" in device.get("name", ""):
            print(device["udid"])
            raise SystemExit(0)
raise SystemExit("No available iPhone simulator found")'
)"
echo "Simulator: $SIMULATOR_ID"
xcrun simctl boot "$SIMULATOR_ID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$SIMULATOR_ID" -b
xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
xcrun simctl launch "$SIMULATOR_ID" com.codex.minidiablo
sleep 3
xcrun simctl terminate "$SIMULATOR_ID" com.codex.minidiablo >/dev/null 2>&1 || true
