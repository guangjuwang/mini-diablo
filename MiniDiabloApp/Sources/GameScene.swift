import SpriteKit
import UIKit

final class GameScene: SKScene {
    private let map = DungeonMap.blackHollowChapterOne()
    private var chapter: ChapterDefinition?
    private var run = ChapterOneRun()
    private var spriteSheet = SKTexture(imageNamed: AssetCatalog.spriteSheetImageName)
    private var uiAtlas = SKTexture(imageNamed: AssetCatalog.uiAtlasImageName)
    private let worldNode = SKNode()
    private let uiNode = SKNode()
    private var heroNode: SKSpriteNode?
    private var enemyNodes: [String: SKSpriteNode] = [:]
    private var enemyState: [String: Combatant] = [:]
    private let enemySpawnPoints: [String: GridPoint] = [
        "skeleton-a": GridPoint(x: 5, y: 1),
        "skeleton-b": GridPoint(x: 7, y: 3),
        "ash-warlock": GridPoint(x: 11, y: 7)
    ]
    private var relicNodes: [SKSpriteNode] = []
    private var collectedRelics: Set<String> = []
    private var gateNode: SKSpriteNode?
    private var archivistNode: SKSpriteNode?
    private var tileSize: CGFloat = 32
    private var mapOrigin: CGPoint = .zero
    private var heroPoint = GridPoint(x: 1, y: 1)
    private var relicsCollected = 0
    private var gateOpen = false
    private var heroDefeated = false
    private var questLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private var storyLabel = SKLabelNode(fontNamed: "Menlo")
    private var statsLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private var codexPanel: SKNode?
    private var inventoryPanel: SKNode?
    private var lootToast: SKNode?

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.04, green: 0.05, blue: 0.06, alpha: 1)
        spriteSheet.filteringMode = .nearest
        uiAtlas.filteringMode = .nearest
        chapter = loadChapter()
        addChild(worldNode)
        addChild(uiNode)
        seedEnemies()
        buildWorld()
        buildUI()
        showStory(for: .bellAwakened)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard oldSize != .zero else {
            return
        }
        worldNode.removeAllChildren()
        uiNode.removeAllChildren()
        buildWorld()
        buildUI()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else {
            return
        }
        let node = atPoint(point)
        if let name = node.name ?? node.parent?.name {
            handleNamedTouch(name)
            return
        }
        moveHero(toward: point)
    }

    private func loadChapter() -> ChapterDefinition? {
        let directURL = Bundle.main.url(forResource: "chapter1", withExtension: "json")
        let storyURL = Bundle.main.url(forResource: "chapter1", withExtension: "json", subdirectory: "Story")
        guard
            let url = storyURL ?? directURL,
            let data = try? Data(contentsOf: url),
            let decoded = try? StoryCatalog.decodeChapter(data: data)
        else {
            return nil
        }
        return decoded
    }

    private func buildWorld() {
        enemyNodes.removeAll()
        relicNodes.removeAll()
        gateNode = nil
        archivistNode = nil
        heroNode = nil

        tileSize = floor(min(size.width / CGFloat(map.width), (size.height - 168) / CGFloat(map.height)))
        mapOrigin = CGPoint(
            x: floor((size.width - CGFloat(map.width) * tileSize) / 2),
            y: 148
        )

        for tile in map.tiles {
            let node = SKSpriteNode(texture: texture(for: tile.kind))
            node.size = CGSize(width: tileSize, height: tileSize)
            node.position = scenePoint(for: tile.point)
            node.zPosition = zPosition(for: tile.kind)
            node.name = touchName(for: tile.kind, point: tile.point)
            worldNode.addChild(node)

            if tile.kind == .gate {
                gateNode = node
                if gateOpen {
                    node.alpha = 0.38
                    node.name = nil
                }
            }

            if tile.kind == .relic {
                let relicName = "relic-\(tile.point.x)-\(tile.point.y)"
                guard collectedRelics.contains(relicName) == false else {
                    continue
                }
                let relic = SKSpriteNode(texture: texture(column: 0, row: 3))
                relic.size = CGSize(width: tileSize * 0.74, height: tileSize * 0.74)
                relic.position = node.position
                relic.zPosition = 20
                relic.name = relicName
                relicNodes.append(relic)
                worldNode.addChild(relic)
            }
        }

        addActorNodes()
        for id in enemySpawnPoints.keys.sorted() {
            guard let point = enemySpawnPoints[id], let combatant = enemyState[id], combatant.isDefeated == false else {
                continue
            }
            addEnemy(id: id, point: point, combatant: combatant)
        }
    }

    private func seedEnemies() {
        enemyState = [
            "skeleton-a": CombatResolver.skeleton(id: "skeleton-a"),
            "skeleton-b": CombatResolver.skeleton(id: "skeleton-b"),
            "ash-warlock": CombatResolver.ashWarlock()
        ]
    }

    private func addActorNodes() {
        let hero = SKSpriteNode(texture: texture(column: 0, row: 0))
        hero.size = CGSize(width: tileSize * 1.35, height: tileSize * 1.35)
        hero.position = scenePoint(for: heroPoint)
        hero.zPosition = 30
        hero.name = "hero"
        heroNode = hero
        worldNode.addChild(hero)

        let archivist = SKSpriteNode(texture: texture(column: 3, row: 0))
        archivist.size = CGSize(width: tileSize * 1.25, height: tileSize * 1.25)
        archivist.position = scenePoint(for: GridPoint(x: 3, y: 3))
        archivist.zPosition = 25
        archivist.name = "archivist"
        archivistNode = archivist
        worldNode.addChild(archivist)
    }

    private func addEnemy(id: String, point: GridPoint, combatant: Combatant) {
        let coordinates = id == "ash-warlock" ? (2, 0) : (1, 0)
        let enemy = SKSpriteNode(texture: texture(column: coordinates.0, row: coordinates.1))
        enemy.size = CGSize(width: tileSize * (id == "ash-warlock" ? 1.65 : 1.22), height: tileSize * (id == "ash-warlock" ? 1.65 : 1.22))
        enemy.position = scenePoint(for: point)
        enemy.zPosition = 28
        enemy.name = "enemy-\(id)"
        enemyNodes[id] = enemy
        enemyState[id] = combatant
        worldNode.addChild(enemy)
    }

    private func buildUI() {
        let panelFill = SKShapeNode(rectOf: CGSize(width: size.width, height: 140))
        panelFill.fillColor = UIColor(red: 0.08, green: 0.09, blue: 0.10, alpha: 0.96)
        panelFill.strokeColor = .clear
        panelFill.position = CGPoint(x: size.width / 2, y: 70)
        panelFill.name = "ui"
        panelFill.zPosition = 99
        uiNode.addChild(panelFill)

        let panelFrame = SKSpriteNode(texture: uiTexture(column: 0, row: 0))
        panelFrame.size = CGSize(width: size.width - 18, height: 126)
        panelFrame.position = CGPoint(x: size.width / 2, y: 70)
        panelFrame.name = "ui"
        panelFrame.zPosition = 101
        uiNode.addChild(panelFrame)

        let healthOrb = SKSpriteNode(texture: uiTexture(column: 1, row: 0))
        healthOrb.size = CGSize(width: 42, height: 42)
        healthOrb.position = CGPoint(x: 36, y: 32)
        healthOrb.name = "ui"
        healthOrb.zPosition = 112
        uiNode.addChild(healthOrb)

        let manaOrb = SKSpriteNode(texture: uiTexture(column: 2, row: 0))
        manaOrb.size = CGSize(width: 42, height: 42)
        manaOrb.position = CGPoint(x: 82, y: 32)
        manaOrb.name = "ui"
        manaOrb.zPosition = 112
        uiNode.addChild(manaOrb)

        questLabel = label(font: "Menlo-Bold", size: 14, color: UIColor(red: 0.94, green: 0.82, blue: 0.48, alpha: 1))
        questLabel.position = CGPoint(x: 16, y: 112)
        questLabel.horizontalAlignmentMode = .left
        questLabel.verticalAlignmentMode = .top
        questLabel.name = "ui"
        uiNode.addChild(questLabel)

        storyLabel = label(font: "Menlo", size: 12, color: UIColor(red: 0.82, green: 0.86, blue: 0.80, alpha: 1))
        storyLabel.position = CGPoint(x: 16, y: 82)
        storyLabel.horizontalAlignmentMode = .left
        storyLabel.verticalAlignmentMode = .top
        storyLabel.preferredMaxLayoutWidth = size.width - 32
        storyLabel.numberOfLines = 3
        storyLabel.name = "ui"
        uiNode.addChild(storyLabel)

        statsLabel = label(font: "Menlo-Bold", size: 12, color: .white)
        statsLabel.position = CGPoint(x: 16, y: 22)
        statsLabel.horizontalAlignmentMode = .left
        statsLabel.name = "ui"
        uiNode.addChild(statsLabel)

        addButton(title: "Codex", name: "codex", x: size.width - 62, y: 112, textureColumn: 1, textureRow: 1)
        addButton(title: "Potion", name: "potion", x: size.width - 62, y: 68, textureColumn: 2, textureRow: 1)
        addButton(title: "Bag", name: "inventory", x: size.width - 62, y: 24, textureColumn: 0, textureRow: 1)
        updateUI()
    }

    private func addButton(title: String, name: String, x: CGFloat, y: CGFloat, textureColumn: Int, textureRow: Int) {
        let button = SKSpriteNode(texture: uiTexture(column: textureColumn, row: textureRow))
        button.size = CGSize(width: 92, height: 38)
        button.position = CGPoint(x: x, y: y)
        button.name = name
        button.zPosition = 110
        uiNode.addChild(button)

        let text = label(font: "Menlo-Bold", size: 13, color: .white)
        text.text = title
        text.verticalAlignmentMode = .center
        text.position = .zero
        text.name = name
        button.addChild(text)
    }

    private func handleNamedTouch(_ name: String) {
        if name == "codex" {
            toggleCodex()
        } else if name == "potion" {
            usePotion()
        } else if name == "inventory" {
            toggleInventory()
        } else if name == "ui" {
            return
        } else if name == "archivist" {
            guard isNear(heroPoint, GridPoint(x: 3, y: 3), range: 1) else {
                storyLabel.text = "Archivist Mael lifts the lantern and waits nearby."
                return
            }
            run.meetArchivist()
            showStory(for: .archivistMet)
            pulse(archivistNode)
        } else if name.hasPrefix("relic-") {
            collectRelic(named: name)
        } else if name.hasPrefix("gate-") {
            openGate()
        } else if name.hasPrefix("shrine-") {
            useShrine(named: name)
        } else if name.hasPrefix("enemy-") {
            let id = String(name.dropFirst("enemy-".count))
            attackEnemy(id: id)
        }
        updateUI()
    }

    private func collectRelic(named name: String) {
        guard let relic = relicNodes.first(where: { $0.name == name }) else {
            return
        }
        guard let relicPoint = gridPoint(fromNamedNode: name), isNear(heroPoint, relicPoint, range: 1) else {
            storyLabel.text = "The relic shard is close enough to hear, and still out of reach."
            return
        }
        collectedRelics.insert(name)
        relicsCollected += 1
        relic.removeFromParent()
        relicNodes.removeAll { $0 === relic }
        if relicsCollected >= 3 {
            run.recoverRelicShard()
            showStory(for: .shardsRecovered)
        } else {
            storyLabel.text = "Relic shard \(relicsCollected)/3 recovered. The remaining shards answer in the dark."
        }
    }

    private func openGate() {
        guard let gatePoint = map.points(for: .gate).first, isNear(heroPoint, gatePoint, range: 1) else {
            storyLabel.text = "The iron gate answers only at arm's reach."
            return
        }
        if run.openIronGate() {
            gateOpen = true
            gateNode?.texture = texture(column: 2, row: 1)
            gateNode?.alpha = 0.38
            gateNode?.name = nil
            showStory(for: .ironGateOpened)
        } else {
            storyLabel.text = "The iron gate waits for the restored violet relic."
        }
    }

    private func useShrine(named name: String) {
        guard let shrinePoint = gridPoint(fromNamedNode: name), isNear(heroPoint, shrinePoint, range: 1) else {
            storyLabel.text = "The shrine glows from across the stones."
            return
        }
        run.hero.restore(health: 36, mana: 24)
        heroDefeated = false
        storyLabel.text = "The shrine restores health and mana."
    }

    private func attackEnemy(id: String) {
        guard heroDefeated == false else {
            storyLabel.text = "The Wanderer is down. Use a Crimson Tonic or shrine to rise."
            return
        }
        guard var enemy = enemyState[id] else {
            return
        }
        guard let enemyPoint = enemySpawnPoints[id], isNear(heroPoint, enemyPoint, range: id == "ash-warlock" ? 2 : 1) else {
            storyLabel.text = "Move closer to strike \(enemy.name)."
            return
        }
        guard id != "ash-warlock" || gateOpen else {
            storyLabel.text = "The Ash Warlock waits beyond the sealed gate."
            return
        }
        let skill: Skill = id == "ash-warlock" ? .relicPulse : .emberSlash
        let event = CombatResolver.attack(attacker: &run.hero, defender: &enemy, skill: skill)
        enemyState[id] = enemy
        storyLabel.text = "\(run.hero.name) uses \(skill.rawValue) for \(event.damage) damage."
        flash(enemyNodes[id], color: .white)

        if enemy.isDefeated {
            enemyNodes[id]?.run(.sequence([.fadeOut(withDuration: 0.18), .removeFromParent()]))
            enemyNodes[id] = nil
            enemyState[id] = nil
            let drops = run.defeat(enemy: enemy)
            showLoot(drops)
            if id == "ash-warlock" {
                showStory(for: .ashWarlockDefeated)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                    self?.showStory(for: .firstChapterComplete)
                    self?.updateUI()
                }
            }
        } else {
            var attacker = enemy
            let counter = CombatResolver.attack(attacker: &attacker, defender: &run.hero)
            enemyState[id] = attacker
            let heroFell = run.hero.isDefeated
            heroDefeated = heroFell
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                guard let self else {
                    return
                }
                if heroFell {
                    self.storyLabel.text = "\(attacker.name) strikes the Wanderer down. Use a Crimson Tonic or shrine to rise."
                } else {
                    self.storyLabel.text = "\(attacker.name) counters for \(counter.damage) damage."
                }
                self.flash(self.heroNode, color: UIColor(red: 0.9, green: 0.16, blue: 0.12, alpha: 1))
                self.updateUI()
            }
        }
    }

    private func usePotion() {
        let before = run.hero.health
        if run.inventory.consumePotion(named: "Crimson Tonic", hero: &run.hero) {
            heroDefeated = false
            if before == 0 {
                storyLabel.text = "Crimson Tonic pulls the Wanderer back to their feet."
            } else {
                storyLabel.text = "Crimson Tonic restores \(run.hero.health - before) health."
            }
        } else {
            storyLabel.text = "The pack is empty of tonics."
        }
    }

    private func moveHero(toward scenePoint: CGPoint) {
        guard heroDefeated == false else {
            storyLabel.text = "The Wanderer is down. Use a Crimson Tonic or shrine to rise."
            return
        }
        let point = gridPoint(for: scenePoint)
        guard map.isWalkable(point, gateOpen: gateOpen) else {
            return
        }
        guard let route = path(from: heroPoint, to: point), route.count > 1 else {
            storyLabel.text = "A wall seal blocks that route."
            return
        }
        heroPoint = point
        let actions = route.dropFirst().map { gridPoint in
            SKAction.move(to: self.scenePoint(for: gridPoint), duration: 0.07)
        }
        heroNode?.run(.sequence(actions))
    }

    private func showStory(for flag: ChapterOneFlag) {
        guard let chapter else {
            storyLabel.text = "Story resource is being prepared."
            return
        }
        if flag == .firstChapterComplete {
            run.story.record(.firstChapterComplete)
        }
        if let beat = chapter.storyBeats.first(where: { $0.triggerFlag == flag.rawValue }) {
            storyLabel.text = "\(beat.speaker): \(beat.line)"
        }
    }

    private func updateUI() {
        if let chapter {
            if run.story.isComplete(chapter: chapter) {
                questLabel.text = "Chapter Complete: \(chapter.title)"
            } else if let quest = run.story.activeQuest(in: chapter) {
                questLabel.text = quest.title
            } else {
                questLabel.text = chapter.title
            }
        } else {
            questLabel.text = "Black Hollow"
        }
        statsLabel.text = "HP \(run.hero.health)/\(run.hero.maxHealth)  MP \(run.hero.mana)/\(run.hero.maxMana)  G \(run.inventory.gold)  Shards \(relicsCollected)/3"
    }

    private func toggleCodex() {
        if let inventoryPanel {
            inventoryPanel.removeFromParent()
            self.inventoryPanel = nil
        }
        if let codexPanel {
            codexPanel.removeFromParent()
            self.codexPanel = nil
            return
        }
        guard let chapter else {
            return
        }

        let panel = SKSpriteNode(texture: uiTexture(column: 0, row: 2))
        panel.size = CGSize(width: size.width - 28, height: min(430, size.height - 190))
        panel.position = CGPoint(x: size.width / 2, y: min(size.height - 235, 360))
        panel.name = "codex"
        panel.zPosition = 150
        uiNode.addChild(panel)

        let title = label(font: "Menlo-Bold", size: 14, color: UIColor(red: 0.70, green: 0.93, blue: 0.86, alpha: 1))
        title.text = chapter.title
        title.position = CGPoint(x: 0, y: panel.frame.height / 2 - 34)
        title.name = "codex"
        panel.addChild(title)

        let completed = run.story.completedQuestCount(in: chapter)
        let body = label(font: "Menlo", size: 12, color: .white)
        body.text = """
        Quest progress: \(completed)/\(chapter.quests.count)
        Flags: \(run.story.sortedFlags.joined(separator: ", "))
        Open threads:
        \(chapter.openThreads.map { "- \($0.hook)" }.joined(separator: "\n"))
        """
        body.position = CGPoint(x: -panel.frame.width / 2 + 18, y: panel.frame.height / 2 - 70)
        body.horizontalAlignmentMode = .left
        body.verticalAlignmentMode = .top
        body.preferredMaxLayoutWidth = panel.frame.width - 36
        body.numberOfLines = 12
        body.name = "codex"
        panel.addChild(body)
        codexPanel = panel
    }

    private func toggleInventory() {
        if let codexPanel {
            codexPanel.removeFromParent()
            self.codexPanel = nil
        }
        if let inventoryPanel {
            inventoryPanel.removeFromParent()
            self.inventoryPanel = nil
            return
        }

        let panel = SKSpriteNode(texture: uiTexture(column: 0, row: 3))
        panel.size = CGSize(width: size.width - 28, height: min(430, size.height - 190))
        panel.position = CGPoint(x: size.width / 2, y: min(size.height - 235, 360))
        panel.name = "inventory"
        panel.zPosition = 150
        uiNode.addChild(panel)

        let title = label(font: "Menlo-Bold", size: 14, color: UIColor(red: 0.96, green: 0.78, blue: 0.42, alpha: 1))
        title.text = "Inventory"
        title.position = CGPoint(x: 0, y: panel.frame.height / 2 - 34)
        title.name = "inventory"
        panel.addChild(title)

        let summary = label(font: "Menlo", size: 12, color: .white)
        summary.text = "Gold \(run.inventory.gold)   Items \(run.inventory.items.count)"
        summary.position = CGPoint(x: -panel.frame.width / 2 + 20, y: panel.frame.height / 2 - 66)
        summary.horizontalAlignmentMode = .left
        summary.name = "inventory"
        panel.addChild(summary)

        let visibleItems = Array(run.inventory.items.prefix(8))
        for (index, item) in visibleItems.enumerated() {
            let column = index % 2
            let row = index / 2
            let slot = SKSpriteNode(texture: uiTexture(column: item.kind == .ring ? 2 : 1, row: 3))
            slot.size = CGSize(width: 42, height: 42)
            slot.position = CGPoint(
                x: -panel.frame.width / 2 + 42 + CGFloat(column) * (panel.frame.width / 2 - 20),
                y: panel.frame.height / 2 - 112 - CGFloat(row) * 52
            )
            slot.name = "inventory"
            panel.addChild(slot)

            let itemLabel = label(font: "Menlo", size: 11, color: UIColor(red: 0.88, green: 0.90, blue: 0.82, alpha: 1))
            itemLabel.text = item.name
            itemLabel.position = CGPoint(x: slot.position.x + 32, y: slot.position.y - 3)
            itemLabel.horizontalAlignmentMode = .left
            itemLabel.name = "inventory"
            panel.addChild(itemLabel)
        }
        inventoryPanel = panel
    }

    private func showLoot(_ drops: [LootItem]) {
        lootToast?.removeFromParent()
        let toast = SKSpriteNode(texture: uiTexture(column: 2, row: 2))
        toast.size = CGSize(width: min(size.width - 48, 310), height: 72)
        toast.position = CGPoint(x: size.width / 2, y: size.height - 72)
        toast.name = "ui"
        toast.zPosition = 180
        uiNode.addChild(toast)

        let lootNames = drops.map(\.name).joined(separator: ", ")
        let label = label(font: "Menlo-Bold", size: 11, color: UIColor(red: 1.0, green: 0.82, blue: 0.42, alpha: 1))
        label.text = "Loot: \(lootNames)"
        label.preferredMaxLayoutWidth = toast.size.width - 28
        label.numberOfLines = 2
        label.name = "ui"
        toast.addChild(label)
        lootToast = toast

        toast.run(.sequence([
            .wait(forDuration: 2.2),
            .fadeOut(withDuration: 0.25),
            .removeFromParent()
        ]))
    }

    private func texture(for kind: TileKind) -> SKTexture {
        switch kind {
        case .wall:
            texture(column: 1, row: 1)
        case .floor, .spawn, .relic, .archivist:
            texture(column: 0, row: 1)
        case .shrine:
            texture(column: 3, row: 1)
        case .gate:
            texture(column: 2, row: 1)
        case .bossArena:
            texture(column: 3, row: 3)
        }
    }

    private func texture(column: Int, row: Int) -> SKTexture {
        let columns = CGFloat(AssetCatalog.spriteColumns)
        let rows = CGFloat(AssetCatalog.spriteRows)
        let rect = CGRect(
            x: CGFloat(column) / columns,
            y: CGFloat(AssetCatalog.spriteRows - 1 - row) / rows,
            width: 1 / columns,
            height: 1 / rows
        )
        let texture = SKTexture(rect: rect, in: spriteSheet)
        texture.filteringMode = .nearest
        return texture
    }

    private func uiTexture(column: Int, row: Int) -> SKTexture {
        let columns = CGFloat(AssetCatalog.uiColumns)
        let rows = CGFloat(AssetCatalog.uiRows)
        let rect = CGRect(
            x: CGFloat(column) / columns,
            y: CGFloat(AssetCatalog.uiRows - 1 - row) / rows,
            width: 1 / columns,
            height: 1 / rows
        )
        let texture = SKTexture(rect: rect, in: uiAtlas)
        texture.filteringMode = .nearest
        return texture
    }

    private func touchName(for kind: TileKind, point: GridPoint) -> String? {
        if kind == .gate {
            return "gate-\(point.x)-\(point.y)"
        }
        if kind == .shrine {
            return "shrine-\(point.x)-\(point.y)"
        }
        return nil
    }

    private func zPosition(for kind: TileKind) -> CGFloat {
        switch kind {
        case .wall, .gate, .shrine:
            12
        case .bossArena:
            2
        default:
            1
        }
    }

    private func scenePoint(for point: GridPoint) -> CGPoint {
        CGPoint(
            x: mapOrigin.x + CGFloat(point.x) * tileSize + tileSize / 2,
            y: mapOrigin.y + CGFloat(map.height - point.y - 1) * tileSize + tileSize / 2
        )
    }

    private func gridPoint(for scenePoint: CGPoint) -> GridPoint {
        let x = Int((scenePoint.x - mapOrigin.x) / tileSize)
        let yFromBottom = Int((scenePoint.y - mapOrigin.y) / tileSize)
        return GridPoint(x: x, y: map.height - yFromBottom - 1)
    }

    private func gridPoint(fromNamedNode name: String) -> GridPoint? {
        let parts = name.split(separator: "-")
        guard parts.count >= 3, let x = Int(parts[parts.count - 2]), let y = Int(parts[parts.count - 1]) else {
            return nil
        }
        return GridPoint(x: x, y: y)
    }

    private func isNear(_ first: GridPoint, _ second: GridPoint, range: Int) -> Bool {
        abs(first.x - second.x) + abs(first.y - second.y) <= range
    }

    private func path(from start: GridPoint, to target: GridPoint) -> [GridPoint]? {
        if start == target {
            return [start]
        }
        var visited: Set<GridPoint> = [start]
        var queue: [GridPoint] = [start]
        var previous: [GridPoint: GridPoint] = [:]

        while queue.isEmpty == false {
            let point = queue.removeFirst()
            for neighbor in map.neighbors(of: point, gateOpen: gateOpen) where visited.contains(neighbor) == false {
                visited.insert(neighbor)
                previous[neighbor] = point
                if neighbor == target {
                    var route: [GridPoint] = [target]
                    var cursor = target
                    while let step = previous[cursor] {
                        route.append(step)
                        cursor = step
                    }
                    return Array(route.reversed())
                }
                queue.append(neighbor)
            }
        }
        return nil
    }

    private func label(font: String, size: CGFloat, color: UIColor) -> SKLabelNode {
        let node = SKLabelNode(fontNamed: font)
        node.fontSize = size
        node.fontColor = color
        node.horizontalAlignmentMode = .center
        node.verticalAlignmentMode = .center
        node.zPosition = 120
        return node
    }

    private func flash(_ node: SKNode?, color: UIColor) {
        guard let node else {
            return
        }
        let colorize = SKAction.colorize(with: color, colorBlendFactor: 0.85, duration: 0.06)
        let clear = SKAction.colorize(withColorBlendFactor: 0, duration: 0.12)
        node.run(.sequence([colorize, clear]))
    }

    private func pulse(_ node: SKNode?) {
        node?.run(.sequence([.scale(to: 1.12, duration: 0.08), .scale(to: 1.0, duration: 0.12)]))
    }
}
