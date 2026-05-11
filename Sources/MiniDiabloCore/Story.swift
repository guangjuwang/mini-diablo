public enum ChapterOneFlag: String, Codable, Sendable, CaseIterable {
    case bellAwakened
    case archivistMet
    case shardsRecovered
    case ironGateOpened
    case ashWarlockDefeated
    case firstChapterComplete
}

public struct ChapterDefinition: Codable, Equatable, Sendable {
    public let id: String
    public let chapterNumber: Int
    public let title: String
    public let status: String
    public let summary: String
    public let completionCriteria: [String]
    public let quests: [QuestDefinition]
    public let storyBeats: [StoryBeat]
    public let openThreads: [OpenThread]
}

public struct QuestDefinition: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let objective: String
    public let completionFlag: String
    public let reward: String
}

public struct StoryBeat: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let triggerFlag: String
    public let speaker: String
    public let line: String
}

public struct OpenThread: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let hook: String
    public let seededBy: String
}

public struct StoryState: Codable, Equatable, Sendable {
    public private(set) var flags: Set<String>

    public init(flags: Set<String> = []) {
        self.flags = flags
    }

    public var sortedFlags: [String] {
        flags.sorted()
    }

    public mutating func record(_ flag: ChapterOneFlag) {
        flags.insert(flag.rawValue)
        if flags.isSuperset(of: Set([
            ChapterOneFlag.bellAwakened.rawValue,
            ChapterOneFlag.archivistMet.rawValue,
            ChapterOneFlag.shardsRecovered.rawValue,
            ChapterOneFlag.ironGateOpened.rawValue,
            ChapterOneFlag.ashWarlockDefeated.rawValue
        ])) {
            flags.insert(ChapterOneFlag.firstChapterComplete.rawValue)
        }
    }

    public func has(_ flag: ChapterOneFlag) -> Bool {
        flags.contains(flag.rawValue)
    }

    public func activeQuest(in chapter: ChapterDefinition) -> QuestDefinition? {
        chapter.quests.first { flags.contains($0.completionFlag) == false }
    }

    public func completedQuestCount(in chapter: ChapterDefinition) -> Int {
        chapter.quests.filter { flags.contains($0.completionFlag) }.count
    }

    public func isComplete(chapter: ChapterDefinition) -> Bool {
        Set(chapter.completionCriteria).isSubset(of: flags)
    }
}

public struct ChapterOneRun: Equatable, Sendable {
    public var hero: Combatant
    public var inventory: PlayerInventory
    public var story: StoryState
    public var enemiesDefeated: Int

    public init(
        hero: Combatant = CombatResolver.hero(),
        inventory: PlayerInventory = PlayerInventory(),
        story: StoryState = StoryState(),
        enemiesDefeated: Int = 0
    ) {
        self.hero = hero
        self.inventory = inventory
        self.story = story
        self.enemiesDefeated = enemiesDefeated
        self.story.record(.bellAwakened)
    }

    public mutating func meetArchivist() {
        story.record(.archivistMet)
    }

    public mutating func recoverRelicShard() {
        story.record(.shardsRecovered)
        inventory.add(LootItem(id: "violet-relic-shard", name: "Violet Relic Shard", kind: .relic, power: 1, storyFlag: ChapterOneFlag.shardsRecovered.rawValue))
    }

    public mutating func openIronGate() -> Bool {
        guard story.has(.shardsRecovered) else {
            return false
        }
        story.record(.ironGateOpened)
        return true
    }

    @discardableResult
    public mutating func defeat(enemy: Combatant) -> [LootItem] {
        enemiesDefeated += 1
        let drops = LootTable.drops(for: enemy.id)
        drops.forEach { inventory.add($0) }
        if enemy.id == "ash-warlock" {
            story.record(.ashWarlockDefeated)
        }
        return drops
    }
}
