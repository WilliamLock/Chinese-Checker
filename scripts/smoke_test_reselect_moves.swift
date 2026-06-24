import Foundation

@main
enum ReselectMovesSmokeTest {
    static func main() {
        let game = ChineseCheckerGame(mode: .twoPlayers)
        let redMarbles = game.marbles
            .filter { $0.player == .red }
            .sorted {
                if $0.coordinate.r == $1.coordinate.r {
                    return $0.coordinate.q < $1.coordinate.q
                }
                return $0.coordinate.r < $1.coordinate.r
            }

        guard redMarbles.count >= 2 else {
            fail("Expected at least two red marbles")
        }

        let firstMoves = game.legalDestinations(for: redMarbles[0])
        let secondMoves = game.legalDestinations(for: redMarbles[1])

        guard !firstMoves.isEmpty else {
            fail("First red marble has no legal destinations")
        }
        guard !secondMoves.isEmpty else {
            fail("Second red marble has no legal destinations")
        }
        guard firstMoves != secondMoves else {
            fail("Reselecting another bead would not change legal destination markers")
        }

        print("reselect moves smoke test passed")
    }

    private static func fail(_ message: String) -> Never {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}
