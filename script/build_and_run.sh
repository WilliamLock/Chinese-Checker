#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Duo Chinese Checkers"
BUNDLE_ID="com.lockstudio.duochinesecheckers"
PROJECT_NAME="ChineseChecker.xcodeproj"
SCHEME="ChineseChecker macOS"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="$ROOT_DIR/build/DerivedData"
PRODUCTS_DIR="$DERIVED_DATA/Build/Products/Debug"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Debug/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true
/usr/bin/xattr -cr "$ROOT_DIR/Shared/Assets.xcassets" >/dev/null 2>&1 || true
/usr/bin/xattr -cr "$ROOT_DIR/build" >/dev/null 2>&1 || true
rm -rf "$APP_BUNDLE"

build_app() {
  xcodebuild \
    -project "$ROOT_DIR/$PROJECT_NAME" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination 'platform=macOS' \
    -derivedDataPath "$DERIVED_DATA" \
    CODE_SIGNING_ALLOWED=NO \
    build
}

prepare_app_bundle() {
  /usr/bin/xattr -cr "$APP_BUNDLE" >/dev/null 2>&1 || true
  /usr/bin/codesign --force --deep --sign - --timestamp=none "$APP_BUNDLE" >/dev/null 2>&1 || true
}

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

if ! build_app; then
  /usr/bin/xattr -cr "$ROOT_DIR/build" >/dev/null 2>&1 || true
  rm -rf "$APP_BUNDLE" "$PRODUCTS_DIR/$APP_NAME.app"
  build_app
fi
prepare_app_bundle

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
