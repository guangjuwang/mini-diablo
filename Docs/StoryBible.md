# Story Bible

## Premise

The Ashbound Wanderer enters Black Hollow after a dead bell rings beneath a ruined belfry. The crypt remembers old oaths through violet relic shards, and Archivist Mael guides the player toward an iron gate that has held the Ash Warlock in place for years.

## Chapter One: Ashes Beneath Black Hollow

Status: complete

Playable arc:

1. Wake at the Ruined Belfry.
2. Survive the skeleton patrol.
3. Meet Archivist Mael.
4. Gather three violet relic shards.
5. Open the iron gate.
6. Defeat the Ash Warlock.
7. Receive chapter completion and open future hooks.

Completion flags:

- `bellAwakened`
- `archivistMet`
- `shardsRecovered`
- `ironGateOpened`
- `ashWarlockDefeated`
- `firstChapterComplete`

## Open Storyline

The first chapter resolves the Black Hollow conflict while preserving future branches:

- The Northern Citadel: the Ash Warlock served a ruler beneath the citadel.
- The Hollow Oath: Archivist Mael recognizes the Wanderer's scar.
- The Three Roads: citadel, marsh, and ruined coast branches remain available for chapter two.

## Materialized Content

The canonical playable story is stored in `MiniDiabloApp/Resources/Story/chapter1.json`. `GameScene.swift` loads that bundled JSON, advances its flags through gameplay actions, and presents story beats through the in-game panel and codex overlay.
