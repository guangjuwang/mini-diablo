# Completion Audit

Date: 2026-05-11

Objective: deliver an offline iOS action RPG in the spirit of classic top-down dungeon crawlers, with pixel-art UI, image-generated assets, an open storyline, a completed first chapter, and validated quality gates.

## Prompt-To-Artifact Checklist

| Requirement | Evidence | Validation |
| --- | --- | --- |
| iOS mobile game | `MiniDiablo.xcodeproj`, shared `MiniDiablo` scheme, `MiniDiabloApp/Sources`, explicit iOS/Simulator build settings, original user-visible title `Black Hollow` | `python3.12 Scripts/validate_project.py`, `plutil`, `xmllint` |
| Local offline game | Bundled Swift, JSON, PNG, asset catalog resources | Offline scan in `Scripts/validate_project.py` |
| Diablo-like gameplay setup | Top-down movement, melee combat, loot, potion, bag, boss, shrine, gate, dungeon map | `Scripts/CoreSmoke/main.swift`, `GameScene.swift` |
| Pixel-art UI | Generated UI atlas drives HUD, health and mana orbs, buttons, codex, bag, loot popup | `MiniDiabloApp/Assets.xcassets/DarkRelicUIAtlas.imageset` |
| Open storyline | Future hooks for Northern Citadel, Hollow Oath, and Three Roads | `MiniDiabloApp/Resources/Story/chapter1.json`, `Docs/StoryBible.md` |
| First chapter completed | Five quest chain with `firstChapterComplete` flag | `chapter1.json`, `ChapterOneRun`, core smoke gate |
| Story materialized alongside game | Game loads `chapter1.json`, advances flags, renders beats and codex | `GameScene.swift`, `StoryCatalog.swift` |
| Image-generated assets | Spritesheet, UI atlas, AppIcon all sourced from imagegen outputs; source files audited; final project PNGs are hash-checked and visually reviewed | `MiniDiabloApp/Resources/generated_assets.json`, `Docs/GeneratedAssets.md`, `Docs/ImageGenPrompts.md` |
| Quality checked | Structural validator, core smoke gate, plist lint, XML lint, full Xcode script, GitHub Actions iOS CI, manual chapter/survival/offline playtest paths, repo hygiene checks, original title/IP wording scan | `Docs/QA.md`, `Docs/ControlsAndPlaytest.md`, `Scripts/validate_project.py`, `Scripts/validate_ios_build.sh`, `.github/workflows/ios-ci.yml`, `.gitignore` |

## Passing Local Gates

```bash
make validate-local
python3.12 Scripts/validate_project.py
swiftc Sources/MiniDiabloCore/Assets.swift Sources/MiniDiabloCore/Combat.swift Sources/MiniDiabloCore/Dungeon.swift Sources/MiniDiabloCore/Items.swift Sources/MiniDiabloCore/Story.swift Scripts/CoreSmoke/main.swift -o /tmp/mini-diablo-core-smoke && /tmp/mini-diablo-core-smoke
python3.12 -m py_compile Scripts/validate_project.py Scripts/chroma_key_png.py
plutil -lint MiniDiablo.xcodeproj/project.pbxproj MiniDiabloApp/Info.plist
xmllint --noout MiniDiablo.xcodeproj/xcshareddata/xcschemes/MiniDiablo.xcscheme MiniDiabloApp/Resources/LaunchScreen.storyboard
```

Latest observed local result:

- PASS story: 5 quests, 3 open hooks
- PASS docs: 7 docs, Makefile, iOS CI
- PASS assets: dark-relic-spritesheet 1024x1024, dark-relic-ui-atlas 1024x1024, dark-relic-app-icon 1024x1024
- PASS app-icons: 18 icon slots
- PASS xcode-project: 14 project references
- PASS offline: 25 Swift/resource files scanned
- PASS storyline-in-game: movement, combat, survival, story flags, codex hooks, inventory, loot, and shrine restoration wired through SpriteKit scene
- PASS core-smoke: combat, survival, loot, inventory, dungeon path, chapter completion
- Project plist and Info.plist OK
- Xcode scheme and LaunchScreen XML OK

## Final Gate

`make validate-ios` runs the full Xcode gate. It reports the active developer directory, checks the iOS Simulator SDK, runs `swift test`, builds the `MiniDiablo` scheme for a generic iOS Simulator destination, installs the app on an available iPhone simulator, and launches it. `.github/workflows/ios-ci.yml` selects Xcode explicitly, prints `xcodebuild -version`, sets up Python 3.12, then runs `make validate-local` and `make validate-ios` on a macOS runner.

Current local environment status: active developer directory is CommandLineTools. `swift test` and a fresh SwiftPM control package both return a `PackageDescription` manifest link error in this environment. Remote GitHub Actions `iOS CI` runs the full Xcode gate on macOS with Xcode and iOS Simulator SDK for every `main` push.

## Completion Status

Status: active pending simulator/device playtest.

Close criteria:

- `make validate-local` passes in the local environment.
- `make validate-ios` passes in GitHub Actions `iOS CI` or on a full Xcode installation with iOS Simulator SDK, including simulator install and launch smoke.
- Chapter One, Survival, and Offline playtest paths run on an iOS Simulator or connected iOS device.
