public struct GeneratedAssetRecord: Codable, Equatable, Sendable {
    public let id: String
    public let fileName: String
    public let source: String
    public let generator: String
    public let promptSummary: String
    public let usedFor: [String]
    public let expectedPixelWidth: Int
    public let expectedPixelHeight: Int
    public let sha256: String
}

public struct GeneratedAssetManifest: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let records: [GeneratedAssetRecord]
}

public enum AssetCatalog {
    public static let spriteSheetImageName = "dark_relic_spritesheet"
    public static let uiAtlasImageName = "dark_relic_ui_atlas"
    public static let spriteColumns = 4
    public static let spriteRows = 4
    public static let uiColumns = 4
    public static let uiRows = 4
}
