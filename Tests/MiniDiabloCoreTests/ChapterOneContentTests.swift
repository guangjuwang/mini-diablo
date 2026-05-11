import XCTest
@testable import MiniDiabloCore

final class ChapterOneContentTests: XCTestCase {
    func testChapterOneJSONContainsCompleteFirstChapterAndOpenHooks() throws {
        let chapter = try loadChapterOne()

        XCTAssertEqual(chapter.id, "chapter-one-black-hollow")
        XCTAssertEqual(chapter.chapterNumber, 1)
        XCTAssertEqual(chapter.status, "complete")
        XCTAssertEqual(chapter.quests.count, 5)
        XCTAssertEqual(Set(chapter.completionCriteria), Set(ChapterOneFlag.allCases.map(\.rawValue)))
        XCTAssertGreaterThanOrEqual(chapter.storyBeats.count, chapter.completionCriteria.count)
        XCTAssertGreaterThanOrEqual(chapter.openThreads.count, 3)

        let questIDs = chapter.quests.map(\.id)
        XCTAssertEqual(Set(questIDs).count, questIDs.count)
        let validFlags = Set(chapter.completionCriteria)
        XCTAssertTrue(chapter.quests.allSatisfy { validFlags.contains($0.completionFlag) })
        let beatIDs = Set(chapter.storyBeats.map(\.id))
        let beatFlags = Set(chapter.storyBeats.map(\.triggerFlag))
        XCTAssertTrue(validFlags.isSubset(of: beatFlags))
        XCTAssertTrue(chapter.openThreads.allSatisfy { beatIDs.contains($0.seededBy) })
        XCTAssertTrue(chapter.openThreads.contains { $0.hook.contains("Northern Citadel") })
        XCTAssertTrue(chapter.openThreads.contains { $0.hook.contains("Hollow Oath") })
        XCTAssertTrue(chapter.openThreads.contains { $0.hook.contains("three possible next paths") })
    }

    func testChapterOneRunCanCompleteAllQuestFlags() throws {
        let chapter = try loadChapterOne()
        var run = ChapterOneRun()

        XCTAssertEqual(run.story.activeQuest(in: chapter)?.id, "q02-archivist")
        run.meetArchivist()
        run.recoverRelicShard()
        XCTAssertTrue(run.openIronGate())
        let drops = run.defeat(enemy: CombatResolver.ashWarlock())

        XCTAssertTrue(drops.contains { $0.id == "ember-ring" })
        XCTAssertTrue(run.story.isComplete(chapter: chapter))
        XCTAssertEqual(run.story.completedQuestCount(in: chapter), chapter.quests.count)
        XCTAssertTrue(run.story.has(.firstChapterComplete))
    }

    func testIronGateRequiresRelicShardFlag() {
        var run = ChapterOneRun()
        XCTAssertFalse(run.openIronGate())

        run.recoverRelicShard()
        XCTAssertTrue(run.openIronGate())
    }

    private func loadChapterOne() throws -> ChapterDefinition {
        let url = repoRoot()
            .appendingPathComponent("MiniDiabloApp/Resources/Story/chapter1.json")
        let data = try Data(contentsOf: url)
        return try StoryCatalog.decodeChapter(data: data)
    }
}
