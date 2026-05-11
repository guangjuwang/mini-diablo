import Foundation

public enum StoryCatalog {
    public static func decodeChapter(data: Data) throws -> ChapterDefinition {
        try JSONDecoder().decode(ChapterDefinition.self, from: data)
    }
}
