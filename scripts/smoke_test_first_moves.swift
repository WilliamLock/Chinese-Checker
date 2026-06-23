import Foundation

@main
enum FirstMovesSmokeTest {
    static func main() {
        var game = ChineseCheckerGame(mode: .computer, difficulty: .medium)

        for turn in 1...3 {
            guard game.currentPlayer == .red else {
                fail("Expected red turn before player move \(turn), got \(game.currentPlayer.displayName)")
            }

            let moves = game.legalMoves(for: .red).sorted { lhs, rhs in
                if lhs.from.r != rhs.from.r {
                    return lhs.from.r < rhs.from.r
                }
                if lhs.from.q != rhs.from.q {
                    return lhs.from.q < rhs.from.q
                }
                if lhs.to.r != rhs.to.r {
                    return lhs.to.r < rhs.to.r
                }
                return lhs.to.q < rhs.to.q
            }

            guard let move = moves.first else {
                fail("No legal red moves on turn \(turn)")
            }

            guard game.move(marbleID: move.marbleID, to: move.to) else {
                fail("Red move \(turn) was rejected: \(move.from) to \(move.to)")
            }

            guard game.marble(at: move.to)?.id == move.marbleID else {
                fail("Red bead did not occupy destination after move \(turn)")
            }

            print("red move \(turn): \(move.from.q),\(move.from.r) -> \(move.to.q),\(move.to.r)")

            if game.winner == nil {
                game.makeComputerMove()
            }
        }

        print("first moves smoke test passed")
    }

    private static func fail(_ message: String) -> Never {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}
