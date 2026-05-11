#!/usr/bin/env python3.12
from __future__ import annotations

import json
import hashlib
import os
import plistlib
import re
import sys
from dataclasses import dataclass
from pathlib import Path

from chroma_key_png import read_png


ROOT = Path(__file__).resolve().parents[1]


@dataclass(frozen=True)
class CheckResult:
    name: str
    detail: str


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_json(relative_path: str) -> dict:
    with (ROOT / relative_path).open("r", encoding="utf-8") as handle:
        return json.load(handle)


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    require(data.startswith(b"\x89PNG\r\n\x1a\n"), f"{path} is a PNG file")
    require(len(data) >= 24, f"{path} includes a PNG IHDR chunk")
    width = int.from_bytes(data[16:20], "big")
    height = int.from_bytes(data[20:24], "big")
    return width, height


def png_alpha_stats(path: Path) -> tuple[int, int, int]:
    width, height, channels, rows = read_png(path)
    require(channels == 4, f"{path} has an alpha channel")
    visible = 0
    transparent_corners = 0
    for x, y in [(0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1)]:
        if rows[y][x * channels + 3] == 0:
            transparent_corners += 1
    for row in rows:
        for index in range(3, len(row), channels):
            if row[index] > 128:
                visible += 1
    return visible, width * height, transparent_corners


def validate_story() -> CheckResult:
    chapter = load_json("MiniDiabloApp/Resources/Story/chapter1.json")
    expected_flags = {
        "bellAwakened",
        "archivistMet",
        "shardsRecovered",
        "ironGateOpened",
        "ashWarlockDefeated",
        "firstChapterComplete",
    }
    require(chapter["status"] == "complete", "chapter one has complete status")
    require(set(chapter["completionCriteria"]) == expected_flags, "chapter one completion flags match the playable flow")
    require(len(chapter["quests"]) >= 5, "chapter one has five playable quests")
    require(len(chapter["storyBeats"]) >= len(expected_flags), "story beats materialize each core flag")
    require(len(chapter["openThreads"]) >= 3, "open storyline hooks exist after chapter one")
    quest_ids = [quest["id"] for quest in chapter["quests"]]
    require(len(set(quest_ids)) == len(quest_ids), "chapter one quest ids are unique")
    quest_flags = {quest["completionFlag"] for quest in chapter["quests"]}
    require(quest_flags.issubset(expected_flags), "chapter one quests use valid completion flags")
    beat_ids = {beat["id"] for beat in chapter["storyBeats"]}
    beat_flags = {beat["triggerFlag"] for beat in chapter["storyBeats"]}
    require(expected_flags.issubset(beat_flags), "chapter one has story beats for every completion flag")
    for thread in chapter["openThreads"]:
        require(thread["seededBy"] in beat_ids, f"{thread['id']} is seeded by a real story beat")
    hook_text = " ".join(thread["hook"] for thread in chapter["openThreads"])
    for hook in ["Northern Citadel", "Hollow Oath", "three possible next paths"]:
        require(hook in hook_text, f"open storyline includes {hook}")
    return CheckResult("story", f"{len(chapter['quests'])} quests, {len(chapter['openThreads'])} open hooks")


def validate_docs() -> CheckResult:
    docs = [
        ROOT / "README.md",
        ROOT / "Docs/StoryBible.md",
        ROOT / "Docs/GeneratedAssets.md",
        ROOT / "Docs/QA.md",
        ROOT / "Docs/CompletionAudit.md",
        ROOT / "Docs/ControlsAndPlaytest.md",
        ROOT / "Docs/ImageGenPrompts.md",
    ]
    for doc in docs:
        require(doc.exists(), f"{doc.relative_to(ROOT)} exists")
    require((ROOT / "Makefile").exists(), "Makefile exists")
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    require(readme.startswith("# Black Hollow"), "README uses the original game title")
    require("`Black Hollow` is the user-visible app title" in readme, "README explains visible title and internal project name")
    user_visible_files = [
        ROOT / "README.md",
        ROOT / "Docs/ControlsAndPlaytest.md",
        ROOT / "Docs/StoryBible.md",
        ROOT / "MiniDiabloApp/Info.plist",
        ROOT / "MiniDiabloApp/Sources/GameScene.swift",
    ]
    for visible_file in user_visible_files:
        visible_text = visible_file.read_text(encoding="utf-8")
        require("Mini Diablo" not in visible_text, f"{visible_file.relative_to(ROOT)} uses original visible title")
        require("Blizzard" not in visible_text, f"{visible_file.relative_to(ROOT)} avoids external franchise naming")
    gitignore = (ROOT / ".gitignore").read_text(encoding="utf-8")
    for ignored in [".build/", ".swiftpm/", "DerivedData/", "xcuserdata/", "*.xcuserstate", "*.dSYM/"]:
        require(ignored in gitignore, f".gitignore excludes {ignored}")
    audit = (ROOT / "Docs/CompletionAudit.md").read_text(encoding="utf-8")
    require("Prompt-To-Artifact Checklist" in audit, "completion audit includes requirement mapping")
    require("make validate-ios" in audit, "completion audit includes full Xcode gate")
    require("Status: active pending simulator/device playtest." in audit, "completion audit tracks active playtest status")
    require("Remote GitHub Actions `iOS CI` runs the full Xcode gate" in audit, "completion audit tracks remote full Xcode CI gate")
    require("Chapter One, Survival, and Offline playtest paths run" in audit, "completion audit includes simulator playtest close criteria")
    controls = (ROOT / "Docs/ControlsAndPlaytest.md").read_text(encoding="utf-8")
    require("Chapter One Playtest Path" in controls, "controls doc includes chapter one playtest path")
    require("Survival Playtest" in controls, "controls doc includes survival playtest path")
    require("the Wanderer rises" in controls, "controls doc covers potion recovery")
    require("shrine restoration clears the downed state" in controls, "controls doc covers shrine recovery")
    require("Offline Playtest" in controls, "controls doc includes offline playtest")
    core_smoke = (ROOT / "Scripts/CoreSmoke/main.swift").read_text(encoding="utf-8")
    require("LootTable.drops" in core_smoke, "core smoke covers loot drops")
    require("consumePotion" in core_smoke, "core smoke covers potion use")
    require("itemHero.restore" in core_smoke, "core smoke covers restore behavior")
    require("defeatSignal.defenderDefeated" in core_smoke, "core smoke covers defeat signaling")
    require("ember-ring" in core_smoke, "core smoke covers boss reward")
    chapter_tests = (ROOT / "Tests/MiniDiabloCoreTests/ChapterOneContentTests.swift").read_text(encoding="utf-8")
    require("Hollow Oath" in chapter_tests, "chapter XCTest covers named open story hooks")
    require("isSubset(of: beatFlags)" in chapter_tests, "chapter XCTest covers story beat flag coverage")
    combat_tests = (ROOT / "Tests/MiniDiabloCoreTests/CombatAndDungeonTests.swift").read_text(encoding="utf-8")
    require("defenderDefeated" in combat_tests, "combat XCTest covers defeat signaling")
    require("consumePotion" in combat_tests, "combat XCTest covers potion recovery")
    prompts = (ROOT / "Docs/ImageGenPrompts.md").read_text(encoding="utf-8")
    require("Gameplay Spritesheet" in prompts, "imagegen prompt doc includes gameplay spritesheet prompt")
    require("UI Atlas" in prompts, "imagegen prompt doc includes UI atlas prompt")
    require("App Icon" in prompts, "imagegen prompt doc includes app icon prompt")
    generated_assets_doc = (ROOT / "Docs/GeneratedAssets.md").read_text(encoding="utf-8")
    manifest = load_json("MiniDiabloApp/Resources/generated_assets.json")
    for record in manifest["records"]:
        require(record["source"] in generated_assets_doc, f"{record['id']} source path appears in generated asset docs")
        require(record["fileName"] in generated_assets_doc, f"{record['id']} file name appears in generated asset docs")
    require("Visual QA on 2026-05-11 confirmed the gameplay spritesheet" in generated_assets_doc, "generated asset docs include spritesheet visual QA")
    require("Visual QA on 2026-05-11 confirmed the UI atlas" in generated_assets_doc, "generated asset docs include UI atlas visual QA")
    require("Visual QA on 2026-05-11 confirmed the AppIcon" in generated_assets_doc, "generated asset docs include app icon visual QA")
    require("Source audit on 2026-05-11 confirmed all three imagegen source files exist locally" in generated_assets_doc, "generated asset docs include source audit")
    require("c048d0a2fa5938eebaff458041c7e0197afc48159c9f31d9b56935331c9e30fb" in generated_assets_doc, "generated asset docs include gameplay source hash")
    require("d6e2e0025ae203500a460d9215b593cf912953d849b4199474fcd6f174cd5704" in generated_assets_doc, "generated asset docs include UI source hash")
    require("2342c534e9c97965970aed25c02495ae2e6ff914d94c595ad6d937c6641de697" in generated_assets_doc, "generated asset docs include app icon source hash")
    workflow = ROOT / ".github/workflows/ios-ci.yml"
    require(workflow.exists(), "iOS CI workflow exists")
    workflow_text = workflow.read_text(encoding="utf-8")
    require("actions/checkout@v6" in workflow_text, "iOS CI workflow uses current checkout action")
    require("actions/setup-python@v6" in workflow_text, "iOS CI workflow sets up Python")
    require("python-version: '3.12'" in workflow_text, "iOS CI workflow uses Python 3.12")
    require("xcodebuild -version" in workflow_text, "iOS CI workflow prints the selected Xcode version")
    require("|| true" not in workflow_text, "iOS CI workflow exposes Xcode selection errors")
    require("make validate-local" in workflow_text, "iOS CI workflow runs local validation")
    require("make validate-ios" in workflow_text, "iOS CI workflow runs full Xcode validation")
    return CheckResult("docs", f"{len(docs)} docs, Makefile, iOS CI")


def validate_assets() -> CheckResult:
    manifest = load_json("MiniDiabloApp/Resources/generated_assets.json")
    records = manifest["records"]
    require(len(records) >= 3, "generated asset manifest contains gameplay, UI, and app icon records")
    asset_directories = {
        "dark-relic-spritesheet": ROOT / "MiniDiabloApp/Assets.xcassets/DarkRelicSpritesheet.imageset",
        "dark-relic-ui-atlas": ROOT / "MiniDiabloApp/Assets.xcassets/DarkRelicUIAtlas.imageset",
        "dark-relic-app-icon": ROOT / "MiniDiabloApp/Assets.xcassets/AppIcon.appiconset",
    }
    validated = []
    for record in records:
        require(record["id"] in asset_directories, f"{record['id']} has a project asset directory")
        target = asset_directories[record["id"]] / record["fileName"]
        require("/.codex/generated_images/" in record["source"], f"{record['id']} records imagegen source path")
        require(target.exists(), f"{record['id']} exists in asset catalog")
        require(record["generator"] == "image_gen built-in tool", f"{record['id']} records image_gen")
        actual_hash = hashlib.sha256(target.read_bytes()).hexdigest()
        require(actual_hash == record["sha256"], f"{record['id']} SHA-256 matches manifest")
        width, height = png_size(target)
        require((width, height) == (record["expectedPixelWidth"], record["expectedPixelHeight"]), f"{record['id']} dimensions match manifest")
        if record["id"] == "dark-relic-app-icon":
            _, _, channels, _ = read_png(target)
            require(channels == 3, f"{record['id']} is an opaque app icon PNG")
        else:
            visible, total, transparent_corners = png_alpha_stats(target)
            require(transparent_corners == 4, f"{record['id']} has transparent corners")
            require(total * 0.08 < visible < total * 0.92, f"{record['id']} has plausible alpha coverage")
        require(target.stat().st_size > 200_000, f"{record['id']} contains substantial generated image data")
        validated.append(f"{record['id']} {width}x{height}")
    return CheckResult("assets", ", ".join(validated))


def validate_app_icons() -> CheckResult:
    contents = load_json("MiniDiabloApp/Assets.xcassets/AppIcon.appiconset/Contents.json")
    checked = 0
    for image in contents["images"]:
        filename = image["filename"]
        size = image["size"]
        scale = image["scale"]
        width_points, height_points = [float(value) for value in size.split("x")]
        multiplier = int(scale.removesuffix("x"))
        expected = (round(width_points * multiplier), round(height_points * multiplier))
        actual = png_size(ROOT / "MiniDiabloApp/Assets.xcassets/AppIcon.appiconset" / filename)
        require(actual == expected, f"{filename} expected {expected} and found {actual}")
        checked += 1
    return CheckResult("app-icons", f"{checked} icon slots")


def validate_xcode_project() -> CheckResult:
    project_path = ROOT / "MiniDiablo.xcodeproj/project.pbxproj"
    project = project_path.read_text(encoding="utf-8")
    expected_paths = [
        "MiniDiabloApp/Sources/AppDelegate.swift",
        "MiniDiabloApp/Sources/GameViewController.swift",
        "MiniDiabloApp/Sources/GameScene.swift",
        "Sources/MiniDiabloCore/Assets.swift",
        "Sources/MiniDiabloCore/Combat.swift",
        "Sources/MiniDiabloCore/Dungeon.swift",
        "Sources/MiniDiabloCore/Items.swift",
        "Sources/MiniDiabloCore/Story.swift",
        "Sources/MiniDiabloCore/StoryCatalog.swift",
        "MiniDiabloApp/Info.plist",
        "MiniDiabloApp/Assets.xcassets",
        "MiniDiabloApp/Resources/LaunchScreen.storyboard",
        "MiniDiabloApp/Resources/Story/chapter1.json",
        "MiniDiabloApp/Resources/generated_assets.json",
    ]
    for relative_path in expected_paths:
        require(relative_path in project, f"{relative_path} is referenced by the Xcode project")
        require((ROOT / relative_path).exists(), f"{relative_path} exists on disk")
    require('productType = "com.apple.product-type.application";' in project, "Xcode target is an iOS application")
    require("SpriteKit.framework" in project, "SpriteKit is linked")
    require("ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;" in project, "Xcode target uses the generated AppIcon asset catalog")
    require("IPHONEOS_DEPLOYMENT_TARGET = 17.0;" in project, "Xcode target uses the iOS 17 deployment target")
    require('TARGETED_DEVICE_FAMILY = "1,2";' in project, "Xcode target supports iPhone and iPad families")
    require('SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";' in project, "Xcode target supports device and simulator platforms")
    require("SDKROOT = iphoneos;" in project, "Xcode project uses the iPhoneOS SDK root")
    require("SWIFT_VERSION = 5.0;" in project, "Xcode target has an explicit Swift language version")
    require("CODE_SIGN_STYLE = Automatic;" in project, "Xcode target uses automatic code signing")
    require("@executable_path/Frameworks" in project, "Xcode target includes app framework runpath")
    require("PRODUCT_BUNDLE_IDENTIFIER = com.codex.minidiablo;" in project, "Xcode target has a stable bundle identifier")
    info = plistlib.loads((ROOT / "MiniDiabloApp/Info.plist").read_bytes())
    require(info.get("CFBundleName") == "Black Hollow", "Info.plist uses the original app name")
    require(info.get("CFBundleDisplayName") == "Black Hollow", "Info.plist uses the original display name")
    require(info.get("UILaunchStoryboardName") == "LaunchScreen", "Info.plist uses LaunchScreen storyboard")
    require(info.get("LSRequiresIPhoneOS") is True, "Info.plist marks the app as iOS-only")
    require("arm64" in info.get("UIRequiredDeviceCapabilities", []), "Info.plist requires arm64 devices")
    require(info.get("UISupportedInterfaceOrientations") == ["UIInterfaceOrientationPortrait"], "Info.plist locks iPhone orientation to portrait")
    ios_build_script = ROOT / "Scripts/validate_ios_build.sh"
    scheme_path = ROOT / "MiniDiablo.xcodeproj/xcshareddata/xcschemes/MiniDiablo.xcscheme"
    require(scheme_path.exists(), "shared Xcode scheme exists")
    scheme = scheme_path.read_text(encoding="utf-8")
    require("BlueprintIdentifier = \"A00000000000000000000501\"" in scheme, "shared Xcode scheme points at MiniDiablo target")
    require(ios_build_script.exists(), "full Xcode build script exists")
    require(os.access(ios_build_script, os.X_OK), "full Xcode build script is executable")
    build_script = ios_build_script.read_text(encoding="utf-8")
    require("xcode-select -p" in build_script, "full Xcode build script reports the developer directory")
    require("Full Xcode is required for iOS Simulator validation." in build_script, "full Xcode build script explains the Xcode requirement")
    require("xcrun --sdk iphonesimulator --show-sdk-path" in build_script, "full Xcode build script checks the iOS Simulator SDK")
    require("swift test" in build_script, "full Xcode build script runs SwiftPM tests")
    require("-scheme MiniDiablo" in build_script, "full Xcode build script uses shared scheme")
    require("generic/platform=iOS Simulator" in build_script, "full Xcode build script targets iOS Simulator")
    require("simctl install" in build_script, "full Xcode build script installs the app on a simulator")
    require("simctl launch" in build_script, "full Xcode build script launches the app on a simulator")
    return CheckResult("xcode-project", f"{len(expected_paths)} project references")


def validate_offline_constraints() -> CheckResult:
    scanned_extensions = {".swift", ".json", ".plist", ".storyboard", ".pbxproj", ".xcscheme"}
    allowed_metadata_urls = [
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd",
    ]
    network_patterns = [
        re.compile(r"\bURLSession\b"),
        re.compile(r"\bWKWebView\b"),
        re.compile(r"\bNWConnection\b"),
        re.compile(r"https?://"),
    ]
    scanned = 0
    for path in ROOT.rglob("*"):
        if ".git" in path.parts or ".build" in path.parts:
            continue
        if path.suffix not in scanned_extensions:
            continue
        text = path.read_text(encoding="utf-8")
        for allowed_url in allowed_metadata_urls:
            text = text.replace(allowed_url, "")
        for pattern in network_patterns:
            require(pattern.search(text) is None, f"{path.relative_to(ROOT)} contains network token {pattern.pattern}")
        scanned += 1
    return CheckResult("offline", f"{scanned} Swift/resource files scanned")


def validate_storyline_in_game() -> CheckResult:
    scene = (ROOT / "MiniDiabloApp/Sources/GameScene.swift").read_text(encoding="utf-8")
    require('forResource: "chapter1"' in scene, "GameScene loads chapter1 JSON from the app bundle")
    require('"Black Hollow"' in scene, "GameScene uses the original game title")
    require("showStory(for: .firstChapterComplete)" in scene, "GameScene shows chapter completion beat")
    require("run.recoverRelicShard()" in scene, "GameScene maps relic collection into story state")
    require("run.openIronGate()" in scene, "GameScene maps gate interaction into story state")
    require("run.defeat(enemy: enemy)" in scene, "GameScene maps boss defeat into story state")
    require("useShrine(named:" in scene, "GameScene exposes shrine restoration")
    require("heroDefeated" in scene, "GameScene tracks hero defeat state")
    require("Use a Crimson Tonic or shrine to rise" in scene, "GameScene exposes recovery guidance")
    require("moveHero(toward:" in scene, "GameScene exposes tap movement")
    require("attackEnemy(id:" in scene, "GameScene exposes melee combat")
    require("usePotion()" in scene, "GameScene exposes potion use")
    require("AssetCatalog.uiAtlasImageName" in scene, "GameScene loads generated UI atlas")
    require("uiTexture(column:" in scene, "GameScene consumes generated UI textures")
    require("chapter.storyBeats.first" in scene, "GameScene renders chapter story beats")
    require("chapter.openThreads.map" in scene, "GameScene renders open storyline hooks")
    require("Quest progress:" in scene, "GameScene renders quest progress in the codex")
    require("toggleInventory()" in scene, "GameScene exposes inventory panel")
    require("showLoot(drops)" in scene, "GameScene displays loot popups")
    return CheckResult("storyline-in-game", "movement, combat, survival, story flags, codex hooks, inventory, loot, and shrine restoration wired through SpriteKit scene")


def main() -> int:
    checks = [
        validate_story,
        validate_docs,
        validate_assets,
        validate_app_icons,
        validate_xcode_project,
        validate_offline_constraints,
        validate_storyline_in_game,
    ]
    results = [check() for check in checks]
    for result in results:
        print(f"PASS {result.name}: {result.detail}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"FAIL {exc}", file=sys.stderr)
        raise SystemExit(1)
