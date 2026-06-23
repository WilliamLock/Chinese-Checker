import Foundation

struct BoardCoordinate: Hashable, Identifiable, Codable {
    let q: Int
    let r: Int

    var id: String { "\(q),\(r)" }

    var s: Int { -q - r }

    func neighbor(in direction: HexDirection) -> BoardCoordinate {
        BoardCoordinate(q: q + direction.q, r: r + direction.r)
    }

    func distance(to other: BoardCoordinate) -> Int {
        (abs(q - other.q) + abs(r - other.r) + abs(s - other.s)) / 2
    }
}

struct HexDirection: Hashable {
    let q: Int
    let r: Int

    static let all: [HexDirection] = [
        HexDirection(q: 1, r: 0),
        HexDirection(q: 1, r: -1),
        HexDirection(q: 0, r: -1),
        HexDirection(q: -1, r: 0),
        HexDirection(q: -1, r: 1),
        HexDirection(q: 0, r: 1)
    ]
}
