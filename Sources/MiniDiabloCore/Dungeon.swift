public enum TileKind: Character, Codable, Sendable {
    case wall = "#"
    case floor = "."
    case spawn = "S"
    case relic = "R"
    case archivist = "A"
    case shrine = "H"
    case gate = "G"
    case bossArena = "B"

    public var baseWalkable: Bool {
        switch self {
        case .wall:
            false
        case .floor, .spawn, .relic, .archivist, .shrine, .bossArena:
            true
        case .gate:
            false
        }
    }
}

public struct GridPoint: Codable, Equatable, Hashable, Sendable {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

public struct DungeonTile: Codable, Equatable, Sendable {
    public let point: GridPoint
    public let kind: TileKind
}

public struct DungeonMap: Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let width: Int
    public let height: Int
    public let tiles: [DungeonTile]

    public init(id: String, name: String, rows: [String]) {
        precondition(Set(rows.map(\.count)).count == 1, "Dungeon rows require equal widths.")
        self.id = id
        self.name = name
        self.width = rows.first?.count ?? 0
        self.height = rows.count

        var parsedTiles: [DungeonTile] = []
        for (y, row) in rows.enumerated() {
            for (x, character) in row.enumerated() {
                let kind = TileKind(rawValue: character) ?? .wall
                parsedTiles.append(DungeonTile(point: GridPoint(x: x, y: y), kind: kind))
            }
        }
        self.tiles = parsedTiles
    }

    public func tile(at point: GridPoint) -> DungeonTile? {
        guard point.x >= 0, point.y >= 0, point.x < width, point.y < height else {
            return nil
        }
        return tiles[point.y * width + point.x]
    }

    public func points(for kind: TileKind) -> [GridPoint] {
        tiles.filter { $0.kind == kind }.map(\.point)
    }

    public func isWalkable(_ point: GridPoint, gateOpen: Bool) -> Bool {
        guard let tile = tile(at: point) else {
            return false
        }
        if tile.kind == .gate {
            return gateOpen
        }
        return tile.kind.baseWalkable
    }

    public func neighbors(of point: GridPoint, gateOpen: Bool) -> [GridPoint] {
        [
            GridPoint(x: point.x + 1, y: point.y),
            GridPoint(x: point.x - 1, y: point.y),
            GridPoint(x: point.x, y: point.y + 1),
            GridPoint(x: point.x, y: point.y - 1)
        ].filter { isWalkable($0, gateOpen: gateOpen) }
    }

    public static func blackHollowChapterOne() -> DungeonMap {
        DungeonMap(
            id: "black-hollow",
            name: "Black Hollow Crypt",
            rows: [
                "##############",
                "#S....R..#H..#",
                "#.####..##...#",
                "#..A..R..G...#",
                "#.####..##...#",
                "#......H##...#",
                "#.########...#",
                "#....R...#B..#",
                "#........#B..#",
                "##############"
            ]
        )
    }
}
