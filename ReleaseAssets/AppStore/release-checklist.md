# App Store Release Checklist

## App Records

- Full app display name: Duo Chinese Checkers
- Lite app display name: Duo Chinese Checkers Lite
- Confirm final public names in App Store Connect before reserving.
- Suggested differentiated names are listed in `RELEASE_PREP.md`.

## Platforms

- iOS / iPadOS
- macOS
- tvOS
- visionOS

## Screenshots

Primary screenshot folder: `Screenshots/`

- iPhone: `chinese-checker-ios-iphone.png`
- iPad: `chinese-checker-ios-ipad.png`
- macOS: `chinese-checker-macos.png`
- tvOS: `chinese-checker-tvos-horizontal-focus.png`
- tvOS input evidence: `chinese-checker-tvos-keyboard-selection.png`
- visionOS: `chinese-checker-visionos-horizontal.png`

Additional winner-state captures are in this folder.

## tvOS Validation

- Board is horizontal on tvOS.
- A selected bead uses a yellow ring.
- Legal destinations use cyan rings.
- Focus uses a white tvOS focus plate/ring.
- Smoke test confirms the first few legal player moves update bead positions.

## Build Notes

Use unsigned local validation builds with `CODE_SIGNING_ALLOWED=NO`.
Distribution archives still require Apple signing configuration.
