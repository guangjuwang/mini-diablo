public enum Faction: String, Codable, Sendable {
    case hero
    case undead
    case neutral
}

public enum Skill: String, Codable, Sendable, CaseIterable {
    case basicStrike
    case emberSlash
    case relicPulse

    public var manaCost: Int {
        switch self {
        case .basicStrike:
            0
        case .emberSlash:
            8
        case .relicPulse:
            14
        }
    }

    public var damageBonus: Int {
        switch self {
        case .basicStrike:
            0
        case .emberSlash:
            7
        case .relicPulse:
            13
        }
    }
}

public struct Combatant: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var name: String
    public var faction: Faction
    public var level: Int
    public var maxHealth: Int
    public var health: Int
    public var maxMana: Int
    public var mana: Int
    public var attackPower: Int
    public var armor: Int
    public var experience: Int

    public init(
        id: String,
        name: String,
        faction: Faction,
        level: Int,
        maxHealth: Int,
        health: Int? = nil,
        maxMana: Int,
        mana: Int? = nil,
        attackPower: Int,
        armor: Int,
        experience: Int = 0
    ) {
        self.id = id
        self.name = name
        self.faction = faction
        self.level = level
        self.maxHealth = maxHealth
        self.health = min(health ?? maxHealth, maxHealth)
        self.maxMana = maxMana
        self.mana = min(mana ?? maxMana, maxMana)
        self.attackPower = attackPower
        self.armor = armor
        self.experience = experience
    }

    public var isDefeated: Bool {
        health <= 0
    }

    public mutating func restore(health healthAmount: Int, mana manaAmount: Int) {
        health = min(maxHealth, health + max(0, healthAmount))
        mana = min(maxMana, mana + max(0, manaAmount))
    }
}

public struct CombatEvent: Equatable, Sendable {
    public let attackerID: String
    public let defenderID: String
    public let skill: Skill
    public let damage: Int
    public let defenderDefeated: Bool
    public let manaSpent: Int
}

public enum CombatResolver {
    public static func hero() -> Combatant {
        Combatant(
            id: "hero",
            name: "Ashbound Wanderer",
            faction: .hero,
            level: 1,
            maxHealth: 88,
            maxMana: 38,
            attackPower: 15,
            armor: 4
        )
    }

    public static func skeleton(id: String = "skeleton-raider") -> Combatant {
        Combatant(
            id: id,
            name: "Skeleton Raider",
            faction: .undead,
            level: 1,
            maxHealth: 32,
            maxMana: 0,
            attackPower: 9,
            armor: 2
        )
    }

    public static func ashWarlock() -> Combatant {
        Combatant(
            id: "ash-warlock",
            name: "Ash Warlock",
            faction: .undead,
            level: 3,
            maxHealth: 118,
            maxMana: 52,
            attackPower: 18,
            armor: 5
        )
    }

    @discardableResult
    public static func attack(
        attacker: inout Combatant,
        defender: inout Combatant,
        skill: Skill = .basicStrike
    ) -> CombatEvent {
        let spentMana = min(attacker.mana, skill.manaCost)
        let activeBonus = spentMana == skill.manaCost ? skill.damageBonus : 0
        attacker.mana -= spentMana
        let rawDamage = attacker.attackPower + activeBonus + attacker.level
        let damage = max(1, rawDamage - defender.armor)
        defender.health = max(0, defender.health - damage)

        return CombatEvent(
            attackerID: attacker.id,
            defenderID: defender.id,
            skill: skill,
            damage: damage,
            defenderDefeated: defender.isDefeated,
            manaSpent: spentMana
        )
    }
}
