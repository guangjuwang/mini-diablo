# Black Hollow

Black Hollow is a local-first iOS SpriteKit action RPG prototype with dark fantasy, top-down dungeon crawling, tap movement, melee combat, loot, story flags, and a completed first chapter.

`Black Hollow` is the user-visible app title. `MiniDiablo` remains the internal Xcode project, target, scheme, and package codename.

## Deliverables

- Native iOS app project: `MiniDiablo.xcodeproj`
- SpriteKit game scene: `MiniDiabloApp/Sources/GameScene.swift`
- Offline gameplay core: `Sources/MiniDiabloCore`
- Completed first chapter JSON: `MiniDiabloApp/Resources/Story/chapter1.json`
- Generated pixel-art asset sheet: `MiniDiabloApp/Assets.xcassets/DarkRelicSpritesheet.imageset/dark_relic_spritesheet.png`
- Generated pixel-art UI atlas: `MiniDiabloApp/Assets.xcassets/DarkRelicUIAtlas.imageset/dark_relic_ui_atlas.png`
- Generated pixel-art AppIcon set: `MiniDiabloApp/Assets.xcassets/AppIcon.appiconset`
- Standard iOS launch screen: `MiniDiabloApp/Resources/LaunchScreen.storyboard`
- Local validation gate: `python3.12 Scripts/validate_project.py`
- Completion audit: `Docs/CompletionAudit.md`
- Controls and playtest path: `Docs/ControlsAndPlaytest.md`
- Image generation prompts: `Docs/ImageGenPrompts.md`

## Gameplay

The first chapter takes place in Black Hollow Crypt. The player wakes at the ruined belfry, fights skeleton raiders, survives enemy counterattacks, collects loot, uses potions and shrines, opens the bag, meets Archivist Mael, gathers three violet relic shards, opens the iron gate, defeats the Ash Warlock, earns the Ember Ring, and reaches chapter completion. The codex panel keeps the wider storyline open through three follow-up hooks: the Northern Citadel, the Hollow Oath, and three roads beyond the graveyard.

## Run

1. Open `MiniDiablo.xcodeproj` in Xcode.
2. Select the `MiniDiablo` iOS app target.
3. Choose an iPhone simulator or connected iOS device.
4. Build and run.

The game uses bundled JSON and PNG assets only. Runtime gameplay runs fully offline.

## Validate

```bash
make validate-local
python3.12 Scripts/validate_project.py
swiftc Sources/MiniDiabloCore/Assets.swift Sources/MiniDiabloCore/Combat.swift Sources/MiniDiabloCore/Dungeon.swift Sources/MiniDiabloCore/Items.swift Sources/MiniDiabloCore/Story.swift Scripts/CoreSmoke/main.swift -o /tmp/mini-diablo-core-smoke && /tmp/mini-diablo-core-smoke
plutil -lint MiniDiablo.xcodeproj/project.pbxproj MiniDiabloApp/Info.plist
xmllint --noout MiniDiablo.xcodeproj/xcshareddata/xcschemes/MiniDiablo.xcscheme MiniDiabloApp/Resources/LaunchScreen.storyboard
make validate-ios
```

Swift Package tests are included under `Tests/MiniDiabloCoreTests`. The current machine uses a CommandLineTools-only developer profile; a full Xcode installation supplies the SwiftPM XCTest and iOS SDK build gate. The local validation gate uses Python structural checks plus plist/project linting in this environment.
