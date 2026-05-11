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

xcodebuild \
  -project MiniDiablo.xcodeproj \
  -scheme MiniDiablo \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  build
