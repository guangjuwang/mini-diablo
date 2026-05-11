# Generated Assets

Mode: imagegen built-in tool

Full prompts: `Docs/ImageGenPrompts.md`

Project asset:

- `MiniDiabloApp/Assets.xcassets/DarkRelicSpritesheet.imageset/dark_relic_spritesheet.png`
- `MiniDiabloApp/Assets.xcassets/DarkRelicUIAtlas.imageset/dark_relic_ui_atlas.png`
- `MiniDiabloApp/Assets.xcassets/AppIcon.appiconset/icon-1024.png`

Source image:

- Gameplay spritesheet source: `/Users/guangjuwang/.codex/generated_images/019e14e4-5248-7dc3-a654-f3838659a828/ig_0d8f2b3196e21963016a0141d78c808191be8d99806d191595.png`
- UI atlas source: `/Users/guangjuwang/.codex/generated_images/019e14e4-5248-7dc3-a654-f3838659a828/ig_0d8f2b3196e21963016a01475a039c8191854eef20fb9f2d24.png`
- App icon source: `/Users/guangjuwang/.codex/generated_images/019e14e4-5248-7dc3-a654-f3838659a828/ig_0d8f2b3196e21963016a014fe1e0a88191bc1d013881e4d038.png`

Final prompt summary:

Create a 4x4 dark fantasy top-down pixel art spritesheet with a hooded hero, skeleton raider, ash warlock boss, archivist NPC, dungeon floor, wall, iron gate, shrine, potion icons, weapon and ring loot, relic shard, slash effect, shadow projectile, and ember-veined boss arena. Create a second 4x4 dark fantasy UI atlas with HUD frame, health and mana orbs, button frames, codex panel, quest tracker, loot popup, portrait frame, menu frame, inventory slots, and joystick ring. Both atlas prompts use a solid `#00ff00` chroma-key background for local alpha extraction. Create a dedicated opaque iOS app icon with a hooded wanderer, glowing sword, iron gate, ember-lit crypt stones, and teal rune accent.

Usage:

- Player sprite
- Enemy sprites
- NPC sprite
- Dungeon tiles
- Loot icons
- Combat effects
- App icon source
- HUD frame
- Health and mana orbs
- Button frames
- Codex and quest panels
- iOS AppIcon set

QA:

- Final project PNGs resized to `1024x1024`.
- `Scripts/chroma_key_png.py` converts chroma-key backgrounds to alpha with Python 3.12 standard library code.
- Asset manifest records the generator, source paths, project paths, usage, and expected dimensions.
- Asset manifest records SHA-256 hashes for drift detection.
- `Scripts/validate_project.py` treats imagegen source paths as audit records and verifies project PNG headers, alpha channels, transparent corners, dimensions, hashes, and project references.
- Visual QA on 2026-05-11 confirmed the gameplay spritesheet contains distinct hero, skeleton, ash warlock, archivist, dungeon tiles, shrine, potions, loot, relic, effects, and boss arena cells.
- Visual QA on 2026-05-11 confirmed the UI atlas contains readable HUD, health orb, mana orb, button frames, codex panel, quest strip, loot frame, portrait frame, inventory slots, and joystick ring cells.
- Visual QA on 2026-05-11 confirmed the AppIcon reads clearly as a hooded dungeon wanderer in front of an iron gate with teal rune and ember lighting accents.
- Source audit on 2026-05-11 confirmed all three imagegen source files exist locally at `1254x1254`.
- Source SHA-256: gameplay spritesheet `c048d0a2fa5938eebaff458041c7e0197afc48159c9f31d9b56935331c9e30fb`, UI atlas `d6e2e0025ae203500a460d9215b593cf912953d849b4199474fcd6f174cd5704`, AppIcon `2342c534e9c97965970aed25c02495ae2e6ff914d94c595ad6d937c6641de697`.
