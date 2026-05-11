import XCTest
@testable import MiniDiabloCore

final class GeneratedAssetTests: XCTestCase {
    func testGeneratedAssetManifestPointsAtProjectAsset() throws {
        let manifestURL = repoRoot().appendingPathComponent("MiniDiabloApp/Resources/generated_assets.json")
        let data = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(GeneratedAssetManifest.self, from: data)
        let assetDirectories = [
            "dark-relic-spritesheet": "DarkRelicSpritesheet.imageset",
            "dark-relic-ui-atlas": "DarkRelicUIAtlas.imageset",
            "dark-relic-app-icon": "AppIcon.appiconset"
        ]
        XCTAssertEqual(Set(manifest.records.map(\.id)), Set(assetDirectories.keys))

        for record in manifest.records {
            XCTAssertEqual(record.generator, "image_gen built-in tool")
            XCTAssertGreaterThan(record.usedFor.count, 2)
            let directory = try XCTUnwrap(assetDirectories[record.id])
            let imageURL = repoRoot()
                .appendingPathComponent("MiniDiabloApp/Assets.xcassets")
                .appendingPathComponent(directory)
                .appendingPathComponent(record.fileName)
            XCTAssertTrue(FileManager.default.fileExists(atPath: imageURL.path))

            let size = try pngSize(at: imageURL)
            XCTAssertEqual(size.width, record.expectedPixelWidth)
            XCTAssertEqual(size.height, record.expectedPixelHeight)
        }
    }

    private func pngSize(at url: URL) throws -> (width: Int, height: Int) {
        let data = try Data(contentsOf: url)
        XCTAssertGreaterThanOrEqual(data.count, 24)
        let width = Int(UInt32(data[16]) << 24 | UInt32(data[17]) << 16 | UInt32(data[18]) << 8 | UInt32(data[19]))
        let height = Int(UInt32(data[20]) << 24 | UInt32(data[21]) << 16 | UInt32(data[22]) << 8 | UInt32(data[23]))
        return (width, height)
    }
}
