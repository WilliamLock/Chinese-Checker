# Duo Chinese Checkers

A simplified Chinese Checkers game for Apple platforms, built with shared SwiftUI and shared game logic.

## Targets

- `ChineseChecker iOS`: full iPhone/iPad build.
- `ChineseChecker macOS`: full macOS build.
- `ChineseChecker tvOS`: full Apple TV build with horizontal board layout and remote/keyboard focus support.
- `ChineseChecker visionOS`: full Apple Vision Pro build with horizontal board layout.
- `ChineseChecker Lite iOS`: Lite iPhone/iPad build.
- `ChineseChecker Lite macOS`: Lite macOS build.
- `ChineseChecker Lite tvOS`: Lite Apple TV build.
- `ChineseChecker Lite visionOS`: Lite Apple Vision Pro build.

## Gameplay

- Two-player local play
- Player vs computer
- Three computer levels
- Simplified two-camp board
- Tap a marble, then tap a highlighted destination
- Adjacent moves and single/multi-jump destinations
- tvOS focus ring, selected bead ring, and highlighted legal destinations
- Undo, hint, restart, and mode controls

## Verified Builds

Validated locally with unsigned builds:

```sh
xcodebuild -project ChineseChecker.xcodeproj -scheme "ChineseChecker iOS" -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project ChineseChecker.xcodeproj -scheme "ChineseChecker macOS" -configuration Release -destination 'generic/platform=macOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project ChineseChecker.xcodeproj -scheme "ChineseChecker tvOS" -configuration Release -destination 'generic/platform=tvOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project ChineseChecker.xcodeproj -scheme "ChineseChecker visionOS" -configuration Release -destination 'generic/platform=visionOS' CODE_SIGNING_ALLOWED=NO build
```

Lite schemes use the same platform destinations with `ChineseChecker Lite ...` scheme names.

## tvOS Move Smoke Test

```sh
swiftc Shared/Models/BoardCoordinate.swift Shared/Models/GameModels.swift Shared/Models/ChineseCheckerGame.swift scripts/smoke_test_first_moves.swift -o /tmp/chinese_checker_first_moves
/tmp/chinese_checker_first_moves
```

Expected output includes three legal red moves and:

```text
first moves smoke test passed
```

## Project Generation

The Xcode project is generated from shared Swift source:

```sh
ruby scripts/generate_project.rb
```

## Release Assets

- Store screenshots: `Screenshots/`
- Additional App Store assets and notes: `ReleaseAssets/AppStore/`
