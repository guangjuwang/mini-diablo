# QA Log

Date: 2026-05-11

## Passing Gates

```bash
make validate-local
python3.12 Scripts/validate_project.py
```

Result:

- PASS story: 5 quests, 3 open hooks
- PASS docs: 7 docs, Makefile, iOS CI
- PASS assets: dark-relic-spritesheet 1024x1024, dark-relic-ui-atlas 1024x1024, dark-relic-app-icon 1024x1024
- PASS app-icons: 18 icon slots
- PASS xcode-project: 14 project references
- PASS offline: 25 Swift/resource files scanned
- PASS storyline-in-game: movement, combat, survival, story flags, codex hooks, inventory, loot, and shrine restoration wired through SpriteKit scene

```bash
swiftc Sources/MiniDiabloCore/Assets.swift Sources/MiniDiabloCore/Combat.swift Sources/MiniDiabloCore/Dungeon.swift Sources/MiniDiabloCore/Items.swift Sources/MiniDiabloCore/Story.swift Scripts/CoreSmoke/main.swift -o /tmp/mini-diablo-core-smoke && /tmp/mini-diablo-core-smoke
```

Result:

- PASS core-smoke: combat, survival, loot, inventory, dungeon path, chapter completion

```bash
plutil -lint MiniDiablo.xcodeproj/project.pbxproj MiniDiabloApp/Info.plist
xmllint --noout MiniDiablo.xcodeproj/xcshareddata/xcschemes/MiniDiablo.xcscheme MiniDiabloApp/Resources/LaunchScreen.storyboard
```

Result:

- `MiniDiablo.xcodeproj/project.pbxproj: OK`
- `MiniDiabloApp/Info.plist: OK`
- `MiniDiablo.xcscheme`: XML OK
- `LaunchScreen.storyboard`: XML OK

## Environment Gate

`make validate-ios` result on this machine:

```text
Scripts/validate_ios_build.sh
Developer directory: /Library/Developer/CommandLineTools
Full Xcode is required for iOS Simulator validation.
Select it with: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
make: *** [validate-ios] Error 1
```

`xcode-select -p` result:

```text
/Library/Developer/CommandLineTools
```

`xcrun --sdk iphonesimulator --show-sdk-path` reports that the `iphonesimulator` SDK lookup belongs to a full Xcode installation. SwiftPM also reports a CommandLineTools SDK/compiler mismatch on this machine.

`swift test` result summary on this machine:

```text
error: 'mini-diablo': Invalid manifest
Undefined symbols for architecture arm64:
  PackageDescription.Package.__allocating_init(...)
  PackageDescription.SwiftVersion.v5(...)
```

A fresh SwiftPM library generated under `/tmp/swiftpm-control.7Xx5NI` returned the same `PackageDescription.Package.__allocating_init(...)` link error, so this is tracked as a local CommandLineTools environment signal.

The repo includes `MiniDiablo.xcodeproj`, a shared `MiniDiablo` scheme, XCTest files, and `.github/workflows/ios-ci.yml` for full Xcode validation. XCTest coverage includes story hook integrity, beat-to-flag coverage, defeat signaling, potion recovery, dungeon reachability, and generated asset manifest checks. The CI workflow selects Xcode explicitly, prints `xcodebuild -version`, sets up Python 3.12, then runs local validation. A full Xcode installation can run the Swift test suite and native iOS build.

Full Xcode command:

```bash
make validate-ios
```
