#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-iphone}"
APP_NAME="Duo Chinese Checkers"
BUNDLE_ID="com.lockstudio.duochinesecheckers"
PROJECT_NAME="ChineseChecker.xcodeproj"
SCHEME="ChineseChecker iOS"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="$ROOT_DIR/build/iOSSimulatorDerivedData"

case "$TARGET" in
  iphone|iPhone)
    SIMULATOR_ID="4FCE8312-665A-4D9D-A7E9-33A78BBB5B6F"
    ;;
  ipad|iPad)
    SIMULATOR_ID="AEFE654B-034F-430C-9BF7-9F8A4F4E12C3"
    ;;
  *)
    SIMULATOR_ID="$TARGET"
    ;;
esac

APP_BUNDLE="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/$APP_NAME.app"

xcrun simctl boot "$SIMULATOR_ID" >/dev/null 2>&1 || true
/usr/bin/open -a Simulator

xcodebuild \
  -project "$ROOT_DIR/$PROJECT_NAME" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  build

xcrun simctl install "$SIMULATOR_ID" "$APP_BUNDLE"
xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID"
