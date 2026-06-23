import Foundation

struct ChineseCheckerGame {
    static let boardRadius = 4
    static let campSize = 4

    private(set) var marbles: [Marble]
    private(set) var currentPlayer: Player
    private(set) var winner: Player?
    private var history: [GameSnapshot]
    var mode: GameMode
    var difficulty: ComputerDifficulty

    let board: [BoardCoordinate]
    let redHome: Set<BoardCoordinate>
    let blueHome: Set<BoardCoordinate>

    init(mode: GameMode = .computer, difficulty: ComputerDifficulty = .medium) {
        self.mode = mode
        self.difficulty = difficulty
        board = Self.makeTwoPlayerBoard()
        redHome = Self.bottomCamp()
        blueHome = Self.topCamp()
        marbles = redHome.sortedByBoardPosition().map { Marble(id: UUID(), player: .red, coordinate: $0) }
            + blueHome.sortedByBoardPosition().map { Marble(id: UUID(), player: .blue, coordinate: $0) }
        currentPlayer = .red
        winner = nil
        history = []
    }

    var occupied: [BoardCoordinate: Marble] {
        Dictionary(uniqueKeysWithValues: marbles.map { ($0.coordinate, $0) })
    }

    var computerShouldMove: Bool {
        mode == .computer && currentPlayer == .blue && winner == nil
    }

    var canUndo: Bool {
        !history.isEmpty
    }

    func marble(at coordinate: BoardCoordinate) -> Marble? {
        occupied[coordinate]
    }

    func legalDestinations(for marble: Marble) -> Set<BoardCoordinate> {
        guard marble.player == currentPlayer, winner == nil else { return [] }

        let boardSet = Set(board)
        let occupiedSet = Set(marbles.map(\.coordinate))
        var destinations = Set<BoardCoordinate>()

        for direction in HexDirection.all {
            let adjacent = marble.coordinate.neighbor(in: direction)
            if boardSet.contains(adjacent), !occupiedSet.contains(adjacent) {
                destinations.insert(adjacent)
            }

            let landing = adjacent.neighbor(in: direction)
            if boardSet.contains(landing),
               occupiedSet.contains(adjacent),
               !occupiedSet.contains(landing) {
                destinations.insert(landing)
                collectJumpDestinations(from: landing, board: boardSet, occupied: occupiedSet, into: &destinations)
            }
        }

        return destinations
    }

    func legalMoves(for player: Player) -> [Move] {
        marbles
            .filter { $0.player == player }
            .flatMap { marble in
                legalDestinationsForAnyTurn(marble).map {
                    Move(marbleID: marble.id, from: marble.coordinate, to: $0)
                }
            }
    }

    mutating func move(marbleID: UUID, to destination: BoardCoordinate) -> Bool {
        guard let index = marbles.firstIndex(where: { $0.id == marbleID }) else { return false }
        let marble = marbles[index]
        guard legalDestinations(for: marble).contains(destination) else { return false }

        history.append(snapshot)
        marbles[index].coordinate = destination
        winner = resolvedWinner()
        if winner == nil {
            currentPlayer = currentPlayer.opponent
        }
        return true
    }

    mutating func makeComputerMove() {
        guard computerShouldMove else { return }
        let moves = legalMoves(for: .blue)
        guard let bestMove = bestComputerMove(from: moves) else { return }
        _ = move(marbleID: bestMove.marbleID, to: bestMove.to)
    }

    mutating func undoLastMove() {
        guard let previous = history.popLast() else { return }
        marbles = previous.marbles
        currentPlayer = previous.currentPlayer
        winner = previous.winner
    }

    mutating func undoPlayerTurn() {
        let steps = mode == .computer && currentPlayer == .red && history.count >= 2 ? 2 : 1
        for _ in 0..<steps {
            undoLastMove()
        }
    }

    mutating func advanceDifficulty() {
        difficulty = difficulty.next
    }

    mutating func prepareScreenshotWinner(_ player: Player = .red) {
        winner = player
    }

    private var snapshot: GameSnapshot {
        GameSnapshot(marbles: marbles, currentPlayer: currentPlayer, winner: winner)
    }

    private func bestComputerMove(from moves: [Move]) -> Move? {
        switch difficulty {
        case .easy:
            return moves.min(by: { score($0, for: .blue) < score($1, for: .blue) })
        case .medium:
            return moves.max(by: { score($0, for: .blue) < score($1, for: .blue) })
        case .hard:
            return moves.max(by: { hardScore($0) < hardScore($1) })
        }
    }

    private func hardScore(_ move: Move) -> Int {
        var copy = self
        _ = copy.move(marbleID: move.marbleID, to: move.to)
        let redResponse = copy.legalMoves(for: .red).map { copy.score($0, for: .red) }.max() ?? 0
        return score(move, for: .blue) * 3 + copy.boardScore(for: .blue) - redResponse * 2
    }

    private func legalDestinationsForAnyTurn(_ marble: Marble) -> Set<BoardCoordinate> {
        let savedCurrentPlayer = currentPlayer
        guard marble.player == savedCurrentPlayer else {
            var copy = self
            copy.currentPlayer = marble.player
            return copy.legalDestinations(for: marble)
        }
        return legalDestinations(for: marble)
    }

    private func collectJumpDestinations(
        from coordinate: BoardCoordinate,
        board: Set<BoardCoordinate>,
        occupied: Set<BoardCoordinate>,
        into destinations: inout Set<BoardCoordinate>
    ) {
        for direction in HexDirection.all {
            let jumped = coordinate.neighbor(in: direction)
            let landing = jumped.neighbor(in: direction)
            guard board.contains(landing),
                  occupied.contains(jumped),
                  !occupied.contains(landing),
                  !destinations.contains(landing) else {
                continue
            }

            destinations.insert(landing)
            collectJumpDestinations(from: landing, board: board, occupied: occupied, into: &destinations)
        }
    }

    private func score(_ move: Move, for player: Player) -> Int {
        let target = player == .blue ? BoardCoordinate(q: -Self.boardRadius, r: Self.boardRadius + Self.campSize) : BoardCoordinate(q: Self.boardRadius, r: -Self.boardRadius - Self.campSize)
        let progress = move.from.distance(to: target) - move.to.distance(to: target)
        return progress * 10 + move.distance
    }

    private func boardScore(for player: Player) -> Int {
        let target = player == .blue ? BoardCoordinate(q: -Self.boardRadius, r: Self.boardRadius + Self.campSize) : BoardCoordinate(q: Self.boardRadius, r: -Self.boardRadius - Self.campSize)
        return marbles
            .filter { $0.player == player }
            .reduce(0) { total, marble in
                total - marble.coordinate.distance(to: target)
            }
    }

    private func resolvedWinner() -> Player? {
        if marbles.filter({ $0.player == .red }).allSatisfy({ blueHome.contains($0.coordinate) }) {
            return .red
        }
        if marbles.filter({ $0.player == .blue }).allSatisfy({ redHome.contains($0.coordinate) }) {
            return .blue
        }
        return nil
    }

    private static func makeBoard(radius: Int) -> [BoardCoordinate] {
        (-radius...radius).flatMap { r in
            let startQ = Int(floor(Double(-radius) - Double(r) / 2.0))
            let endQ = startQ + radius * 2
            return (startQ...endQ).compactMap { q -> BoardCoordinate? in
                if shouldTrimLeftEdge(row: r, q: q, startQ: startQ) { return nil }
                if shouldTrimRightEdge(row: r, q: q, endQ: endQ) { return nil }
                return BoardCoordinate(q: q, r: r)
            }
        }
    }

    private static func shouldTrimLeftEdge(row: Int, q: Int, startQ: Int) -> Bool {
        [-4, -3, -1, 1, 3, 4].contains(row) && q == startQ
    }

    private static func shouldTrimRightEdge(row: Int, q: Int, endQ: Int) -> Bool {
        [-4, 4].contains(row) && q == endQ
    }

    private static func makeTwoPlayerBoard() -> [BoardCoordinate] {
        Array(Set(makeBoard(radius: boardRadius)).union(topCamp()).union(bottomCamp()))
            .sortedByBoardPosition()
    }

    private static func topCamp() -> Set<BoardCoordinate> {
        var camp = Set<BoardCoordinate>()
        for row in 1...campSize {
            let r = -boardRadius - row
            let startQ = row
            let endQ = boardRadius
            for q in startQ...endQ {
                camp.insert(BoardCoordinate(q: q, r: r))
            }
        }
        return camp
    }

    private static func bottomCamp() -> Set<BoardCoordinate> {
        var camp = Set<BoardCoordinate>()
        for row in 1...campSize {
            let r = boardRadius + row
            let startQ = -boardRadius
            let endQ = -row
            for q in startQ...endQ {
                camp.insert(BoardCoordinate(q: q, r: r))
            }
        }
        return camp
    }

}

private struct GameSnapshot {
    let marbles: [Marble]
    let currentPlayer: Player
    let winner: Player?
}

private extension Collection where Element == BoardCoordinate {
    func sortedByBoardPosition() -> [BoardCoordinate] {
        sorted {
            if $0.r == $1.r {
                return $0.q < $1.q
            }
            return $0.r < $1.r
        }
    }
}
