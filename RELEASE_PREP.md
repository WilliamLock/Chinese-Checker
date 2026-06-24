# Release Prep

## Build Matrix

Validated unsigned Release builds from a clean `/tmp/ChineseCheckerReleaseSrc` copy:

- ChineseChecker iOS
- ChineseChecker macOS
- ChineseChecker tvOS
- ChineseChecker visionOS
- ChineseChecker Lite iOS
- ChineseChecker Lite macOS
- ChineseChecker Lite tvOS
- ChineseChecker Lite visionOS

## Screenshot Sets

Screenshots are staged at `/tmp/ChineseCheckerRelease/screenshots`.

- `ios`: 3 iPhone captures
- `ipad`: 3 iPad captures
- `macos`: 3 cropped macOS app captures
- `tvos`: 3 Apple TV captures, plus `04-input-check.png` for input stability evidence
- `visionos`: 3 Apple Vision Pro captures

## App Names

Public App Store search shows many direct collisions around "Chinese Checkers", including Online, Touch, HD, LTE, Ultimate, AI Enhanced, Multiplayer, and Realistic variants. Prefer a differentiated release name.

Recommended candidates:

- Jade Marble Checkers
- Dragon Marble Checkers
- Marble Star Checkers
- Imperial Marble Checkers
- Jade Sternhalma
- Dragon Sternhalma

Current target display names:

- Full version: Duo Chinese Checkers
- Lite version: Duo Chinese Checkers Lite

Final name availability must be confirmed inside App Store Connect when creating the app record.
