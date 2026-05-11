public enum ItemKind: String, Codable, Sendable {
    case potion
    case weapon
    case ring
    case relic
    case gold
}

public struct LootItem: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let kind: ItemKind
    public let power: Int
    public let storyFlag: String?

    public init(id: String, name: String, kind: ItemKind, power: Int, storyFlag: String? = nil) {
        self.id = id
        self.name = name
        self.kind = kind
        self.power = power
        self.storyFlag = storyFlag
    }
}

public struct PlayerInventory: Codable, Equatable, Sendable {
    public private(set) var items: [LootItem]
    public private(set) var gold: Int

    public init(items: [LootItem] = [], gold: Int = 0) {
        self.items = items
        self.gold = gold
    }

    public mutating func add(_ item: LootItem) {
        if item.kind == .gold {
            gold += item.power
        } else {
            items.append(item)
        }
    }

    public mutating func consumePotion(named name: String, hero: inout Combatant) -> Bool {
        guard let index = items.firstIndex(where: { $0.kind == .potion && $0.name == name }) else {
            return false
        }
        let potion = items.remove(at: index)
        if potion.id.contains("mana") {
            hero.restore(health: 0, mana: potion.power)
        } else {
            hero.restore(health: potion.power, mana: 0)
        }
        return true
    }
}

public enum LootTable {
    public static func drops(for defeatedID: String) -> [LootItem] {
        switch defeatedID {
        case "ash-warlock":
            [
                LootItem(id: "ember-ring", name: "Ember Ring", kind: .ring, power: 9),
                LootItem(id: "relic-shard-final", name: "Final Relic Shard", kind: .relic, power: 1, storyFlag: ChapterOneFlag.shardsRecovered.rawValue),
                LootItem(id: "gold-warlock", name: "Warlock Cache", kind: .gold, power: 45)
            ]
        default:
            [
                LootItem(id: "red-potion", name: "Crimson Tonic", kind: .potion, power: 24),
                LootItem(id: "gold-skeleton", name: "Bone Coins", kind: .gold, power: 6)
            ]
        }
    }
}
