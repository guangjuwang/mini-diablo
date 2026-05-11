import XCTest
@testable import MiniDiabloCore

final class CombatAndDungeonTests: XCTestCase {
    func testDeterministicCombatDefeatsSkeletonAndDropsOfflineLoot() {
        var hero = CombatResolver.hero()
        var skeleton = CombatResolver.skeleton()

        let firstHit = CombatResolver.attack(attacker: &hero, defender: &skeleton, skill: .emberSlash)

        XCTAssertEqual(firstHit.manaSpent, Skill.emberSlash.manaCost)
        XCTAssertGreaterThan(firstHit.damage, 0)
        while skeleton.isDefeated == false {
            CombatResolver.attack(attacker: &hero, defender: &skeleton)
        }

        let drops = LootTable.drops(for: skeleton.id)
        XCTAssertTrue(drops.contains { $0.kind == .potion })
        XCTAssertTrue(drops.contains { $0.kind == .gold })
    }

    func testInventoryPotionAndDefeatSignalsSupportSurvivalLoop() {
        var fragileHero = CombatResolver.hero()
        fragileHero.health = 1
        var warlock = CombatResolver.ashWarlock()
        let defeat = CombatResolver.attack(attacker: &warlock, defender: &fragileHero)

        XCTAssertTrue(defeat.defenderDefeated)
        XCTAssertTrue(fragileHero.isDefeated)

        var inventory = PlayerInventory()
        LootTable.drops(for: "skeleton-raider").forEach { inventory.add($0) }
        XCTAssertEqual(inventory.gold, 6)
        XCTAssertTrue(inventory.consumePotion(named: "Crimson Tonic", hero: &fragileHero))
        XCTAssertGreaterThan(fragileHero.health, 0)

        fragileHero.mana = 4
        fragileHero.restore(health: 36, mana: 24)
        XCTAssertLessThanOrEqual(fragileHero.health, fragileHero.maxHealth)
        XCTAssertEqual(fragileHero.mana, 28)
    }

    func testDungeonHasReachableBossArenaWhenGateOpens() throws {
        let map = DungeonMap.blackHollowChapterOne()
        let spawn = try XCTUnwrap(map.points(for: .spawn).first)
        let bossArena = try XCTUnwrap(map.points(for: .bossArena).first)
        let gate = try XCTUnwrap(map.points(for: .gate).first)

        XCTAssertFalse(map.isWalkable(gate, gateOpen: false))
        XCTAssertTrue(map.isWalkable(gate, gateOpen: true))
        XCTAssertFalse(hasPath(from: spawn, to: bossArena, in: map, gateOpen: false))
        XCTAssertTrue(hasPath(from: spawn, to: bossArena, in: map, gateOpen: true))
    }

    private func hasPath(from start: GridPoint, to target: GridPoint, in map: DungeonMap, gateOpen: Bool) -> Bool {
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
}
