import Foundation

enum Player: String, CaseIterable, Codable, Identifiable {
    case red
    case blue

    var id: String { rawValue }

    var opponent: Player {
        switch self {
        case .red: .blue
        case .blue: .red
        }
    }

    var displayName: String {
        switch self {
        case .red: "Red"
        case .blue: "Blue"
        }
    }
}

enum GameMode: String, CaseIterable, Identifiable {
    case twoPlayers
    case computer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .twoPlayers: "Two Players"
        case .computer: "Vs Computer"
        }
    }
}

enum ComputerDifficulty: Int, CaseIterable, Identifiable {
    case easy = 1
    case medium = 2
    case hard = 3

    var id: Int { rawValue }

    var next: ComputerDifficulty {
        switch self {
        case .easy: .medium
        case .medium: .hard
        case .hard: .easy
        }
    }

    var title: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        }
    }
}

struct Marble: Hashable, Identifiable, Codable {
    let id: UUID
    var player: Player
    var coordinate: BoardCoordinate
}

struct Move: Hashable {
    let marbleID: UUID
    let from: BoardCoordinate
    let to: BoardCoordinate

    var distance: Int { from.distance(to: to) }
}
