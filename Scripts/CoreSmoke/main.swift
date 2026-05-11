func require(_ condition: Bool, _ message: String) {
    if condition == false {
        print("FAIL \(message)")
        fatalError(message)
    }
}

func hasPath(from start: GridPoint, to target: GridPoint, in map: DungeonMap, gateOpen: Bool) -> Bool {
    var visited: Set<GridPoint> = [start]
    var queue: [GridPoint] = [start]

    while queue.isEmpty == false {
        let point = queue.removeFirst()
        if point == target {
            return true
        }
        for neighbor in map.neighbors(of: point, gateOpen: gateOpen) where visited.contains(neighbor) == false {
            visited.insert(neighbor)
            queue.append(neighbor)
        }
    }
    return false
}

var hero = CombatResolver.hero()
var skeleton = CombatResolver.skeleton()
let openingStrike = CombatResolver.attack(attacker: &hero, defender: &skeleton, skill: .emberSlash)
require(openingStrike.damage > 0, "combat produces damage")
require(openingStrike.manaSpent == Skill.emberSlash.manaCost, "combat spends skill mana")
while skeleton.isDefeated == false {
    CombatResolver.attack(attacker: &hero, defender: &skeleton)
}
require(skeleton.isDefeated, "skeleton can be defeated")

var fragileHero = CombatResolver.hero()
fragileHero.health = 1
var lethalWarlock = CombatResolver.ashWarlock()
let defeatSignal = CombatResolver.attack(attacker: &lethalWarlock, defender: &fragileHero)
require(defeatSignal.defenderDefeated, "combat reports defender defeat")
require(fragileHero.isDefeated, "hero defeat state is reachable")

let skeletonDrops = LootTable.drops(for: skeleton.id)
var inventory = PlayerInventory()
skeletonDrops.forEach { inventory.add($0) }
require(inventory.gold == 6, "gold drops add to inventory currency")
require(inventory.items.contains { $0.name == "Crimson Tonic" }, "skeleton drops add potion loot")

var itemHero = CombatResolver.hero()
itemHero.health = 40
itemHero.mana = 4
require(inventory.consumePotion(named: "Crimson Tonic", hero: &itemHero), "inventory consumes a health potion")
require(itemHero.health == 64, "health potion restores hero health")
itemHero.restore(health: 36, mana: 24)
require(itemHero.health == itemHero.maxHealth, "shrine-style restore respects max health")
require(itemHero.mana == 28, "shrine-style restore adds mana")

let map = DungeonMap.blackHollowChapterOne()
let spawn = map.points(for: .spawn).first!
let boss = map.points(for: .bossArena).first!
let gate = map.points(for: .gate).first!
require(map.isWalkable(gate, gateOpen: false) == false, "closed gate blocks movement")
require(map.isWalkable(gate, gateOpen: true), "opened gate allows movement")
require(hasPath(from: spawn, to: boss, in: map, gateOpen: false) == false, "closed gate blocks boss arena path")
require(hasPath(from: spawn, to: boss, in: map, gateOpen: true), "boss arena path exists")

var run = ChapterOneRun()
run.meetArchivist()
run.recoverRelicShard()
require(run.openIronGate(), "iron gate opens after shard recovery")
run.defeat(enemy: CombatResolver.ashWarlock())
require(run.inventory.items.contains { $0.id == "ember-ring" }, "boss defeat adds the Ember Ring")
require(run.inventory.gold == 45, "boss defeat adds gold cache")
require(run.story.has(.firstChapterComplete), "first chapter completion flag is reached")

print("PASS core-smoke: combat, survival, loot, inventory, dungeon path, chapter completion")
