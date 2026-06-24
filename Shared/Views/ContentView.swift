import SwiftUI

struct ContentView: View {
    @State private var game = ChineseCheckerGame()
    @State private var selectedMarbleID: UUID?
    @State private var legalDestinations = Set<BoardCoordinate>()
    @State private var focusedCoordinate: BoardCoordinate?
    @State private var didApplyScreenshotState = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.12, blue: 0.08),
                    Color(red: 0.42, green: 0.24, blue: 0.12),
                    Color(red: 0.08, green: 0.05, blue: 0.035)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            BoardView(
                game: game,
                selectedMarbleID: selectedMarbleID,
                legalDestinations: legalDestinations,
                focusedCoordinate: $focusedCoordinate,
                onTap: handleTap
            )
            .ignoresSafeArea()

            VStack {
                topChrome
                Spacer()
                bottomChrome
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 18)

            if let winner = game.winner {
                winnerOverlay(for: winner)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(minWidth: 320, minHeight: 420)
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: game.winner)
        #if os(tvOS)
        .onMoveCommand(perform: handleMoveCommand)
        .onPlayPauseCommand(perform: handleFocusedSelect)
        #endif
        .task(id: game.currentPlayer) {
            applyScreenshotStateIfNeeded()
            focusCurrentPlayerIfNeeded()
            guard game.computerShouldMove else { return }
            try? await Task.sleep(for: .milliseconds(450))
            game.makeComputerMove()
            clearSelection()
            focusCurrentPlayerIfNeeded()
        }
    }

    private var topChrome: some View {
        HStack {
            luxuryIconButton(systemName: "arrow.clockwise") {
                restart(mode: game.mode)
            }
            .accessibilityLabel("New Game")
            .accessibilityIdentifier("newGameButton")

            Spacer()

            playerCapsule

            Spacer()

            hintButton
        }
    }

    private var bottomChrome: some View {
        HStack {
            luxuryIconButton(systemName: "arrow.uturn.backward") {
                undoLastMove()
            }
            .disabled(!game.canUndo)
            .opacity(game.canUndo ? 1 : 0.45)
            .accessibilityLabel("Undo")
            .accessibilityIdentifier("undoButton")

            Spacer()

            modeToggleButton

            Spacer()

            difficultyButton
        }
    }

    private var hintButton: some View {
        luxuryIconButton(systemName: "lightbulb") {
            if let marble = game.marbles.first(where: { $0.player == game.currentPlayer }) {
                selectedMarbleID = marble.id
                legalDestinations = game.legalDestinations(for: marble)
            }
        }
        .disabled(game.computerShouldMove)
        .opacity(game.computerShouldMove ? 0.45 : 1)
        .accessibilityLabel("Hint")
        .accessibilityIdentifier("hintButton")
    }

    private var modeToggleButton: some View {
        Button {
            if !game.computerShouldMove {
                restart(mode: game.mode == .twoPlayers ? .computer : .twoPlayers)
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(currentPlayerFill)
                    .frame(width: 8, height: 8)
                    .shadow(color: currentPlayerGlow, radius: 8)
                Image(systemName: game.mode == .twoPlayers ? "person.2.fill" : "desktopcomputer")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(goldGradient)
            }
            .frame(width: 72, height: 54)
            .background(Color(red: 0.055, green: 0.038, blue: 0.025).opacity(0.92), in: Capsule())
            .overlay {
                Capsule().stroke(goldGradient, lineWidth: 1.3)
            }
            .shadow(color: .black.opacity(0.42), radius: 14, y: 7)
        }
        .buttonStyle(.plain)
        .disabled(game.computerShouldMove)
        .opacity(game.computerShouldMove ? 0.45 : 1)
        .accessibilityLabel(game.mode == .twoPlayers ? "Switch to Computer" : "Switch to Two Players")
        .accessibilityIdentifier("modeToggleButton")
    }

    private var difficultyButton: some View {
        Button {
            guard game.mode == .computer, !game.computerShouldMove else { return }
            game.advanceDifficulty()
            clearSelection()
        } label: {
            VStack(spacing: 4) {
                ForEach(1...3, id: \.self) { level in
                    Capsule()
                        .fill(level <= game.difficulty.rawValue ? AnyShapeStyle(goldGradient) : AnyShapeStyle(Color.white.opacity(0.20)))
                        .frame(width: CGFloat(14 + level * 6), height: 4)
                }
            }
            .frame(width: 54, height: 54)
            .background(Color(red: 0.055, green: 0.038, blue: 0.025).opacity(0.92), in: Circle())
            .overlay {
                Circle().stroke(goldGradient, lineWidth: 1.3)
            }
            .shadow(color: .black.opacity(0.42), radius: 14, y: 7)
        }
        .buttonStyle(.plain)
        .disabled(game.mode != .computer || game.computerShouldMove)
        .opacity(game.mode == .computer && !game.computerShouldMove ? 1 : 0.45)
        .accessibilityLabel("Computer Level \(game.difficulty.rawValue), \(game.difficulty.title)")
        .accessibilityIdentifier("difficultyButton")
    }

    private func winnerOverlay(for winner: Player) -> some View {
        VStack(spacing: 16) {
            gemstoneDot(player: winner, active: true)
                .frame(width: 52, height: 52)

            Text("\(winner.displayName) Wins")
                .font(.system(size: 34, weight: .black, design: .serif))
                .foregroundStyle(goldGradient)
                .multilineTextAlignment(.center)

            Button {
                restart(mode: game.mode)
            } label: {
                Label("New Game", systemImage: "arrow.clockwise")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(red: 0.08, green: 0.05, blue: 0.03))
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                    .background(goldGradient, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .background(Color(red: 0.055, green: 0.038, blue: 0.025).opacity(0.96), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(goldGradient, lineWidth: 1.6)
        }
        .shadow(color: .black.opacity(0.55), radius: 24, y: 14)
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(winner.displayName) wins")
    }

    private var playerCapsule: some View {
        HStack(spacing: 18) {
            gemstoneDot(player: .blue, active: game.currentPlayer == .blue)

            Circle()
                .fill(goldGradient)
                .frame(width: 8, height: 8)

            Rectangle()
                .fill(goldGradient)
                .frame(width: 2, height: 34)

            Circle()
                .fill(goldGradient)
                .frame(width: 8, height: 8)

            gemstoneDot(player: .red, active: game.currentPlayer == .red)
        }
        .padding(.horizontal, 18)
        .frame(height: 58)
        .background(Color(red: 0.055, green: 0.038, blue: 0.025).opacity(0.92), in: Capsule())
        .overlay {
            Capsule().stroke(goldGradient, lineWidth: 1.3)
        }
        .shadow(color: .black.opacity(0.42), radius: 16, y: 8)
    }

    private func luxuryIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(goldGradient)
                .frame(width: 54, height: 54)
                .background(Color(red: 0.055, green: 0.038, blue: 0.025).opacity(0.92), in: Circle())
                .overlay {
                    Circle().stroke(goldGradient, lineWidth: 1.3)
                }
                .shadow(color: .black.opacity(0.42), radius: 14, y: 7)
        }
        .buttonStyle(.plain)
    }

    private func gemstoneDot(player: Player, active: Bool) -> some View {
        Circle()
            .fill(player == .blue ? jadeGradient : rubyGradient)
            .frame(width: active ? 36 : 30, height: active ? 36 : 30)
            .overlay {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.80), .clear],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 22
                        )
                    )
            }
            .overlay {
                Circle().stroke(goldGradient, lineWidth: active ? 2.0 : 1.2)
            }
            .shadow(color: player == .blue ? Color.green.opacity(0.34) : Color.red.opacity(0.36), radius: active ? 10 : 4)
    }

    private var currentPlayerFill: some ShapeStyle {
        game.currentPlayer == .blue ? AnyShapeStyle(jadeGradient) : AnyShapeStyle(rubyGradient)
    }

    private var currentPlayerGlow: Color {
        game.currentPlayer == .blue ? .green.opacity(0.55) : .red.opacity(0.60)
    }

    private var jadeGradient: RadialGradient {
        RadialGradient(
            colors: [
                Color(red: 0.86, green: 1.0, blue: 0.88),
                Color(red: 0.30, green: 0.78, blue: 0.44),
                Color(red: 0.03, green: 0.22, blue: 0.12)
            ],
            center: .topLeading,
            startRadius: 1,
            endRadius: 30
        )
    }

    private var rubyGradient: RadialGradient {
        RadialGradient(
            colors: [
                Color(red: 1.0, green: 0.66, blue: 0.58),
                Color(red: 0.88, green: 0.03, blue: 0.02),
                Color(red: 0.20, green: 0.0, blue: 0.0)
            ],
            center: .topLeading,
            startRadius: 1,
            endRadius: 30
        )
    }

    private var goldGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.84, blue: 0.44),
                Color(red: 0.72, green: 0.38, blue: 0.09)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var restartButton: some View {
        let button = Button {
            restart(mode: game.mode)
        } label: {
            Label("New Game", systemImage: "arrow.clockwise")
        }
        .buttonStyle(.borderedProminent)
        .labelStyle(.iconOnly)
        .controlSize(.regular)

        #if os(macOS) || os(iOS) || os(visionOS)
        return button.keyboardShortcut("n", modifiers: .command)
        #else
        return button
        #endif
    }

    private func handleTap(_ coordinate: BoardCoordinate) {
        guard !game.computerShouldMove, game.winner == nil else { return }

        #if os(tvOS)
        if let selectedMarbleID,
           game.marble(at: coordinate)?.id == selectedMarbleID,
           let destination = preferredDestination(from: coordinate, destinations: legalDestinations),
           game.move(marbleID: selectedMarbleID, to: destination) {
            focusedCoordinate = destination
            clearSelection()
            return
        }

        if let marble = game.marble(at: coordinate),
           marble.player == game.currentPlayer,
           marble.id != selectedMarbleID {
            selectMarble(marble, at: coordinate)
            return
        }
        #endif

        if let selectedMarbleID,
           legalDestinations.contains(coordinate),
           game.move(marbleID: selectedMarbleID, to: coordinate) {
            focusedCoordinate = coordinate
            clearSelection()
            return
        }

        guard let marble = game.marble(at: coordinate), marble.player == game.currentPlayer else {
            #if os(tvOS)
            if selectedMarbleID == nil,
               let nearestMarble = nearestCurrentPlayerMarble(to: coordinate) {
                selectMarble(nearestMarble, at: nearestMarble.coordinate)
                return
            }
            focusedCoordinate = coordinate
            return
            #else
            clearSelection()
            return
            #endif
        }

        selectMarble(marble, at: coordinate)
    }

    private func selectMarble(_ marble: Marble, at coordinate: BoardCoordinate) {
        let destinations = game.legalDestinations(for: marble)
        #if os(tvOS)
        if destinations.isEmpty,
           let nearestMarble = nearestCurrentPlayerMarble(to: coordinate),
           nearestMarble.id != marble.id {
            selectMarble(nearestMarble, at: nearestMarble.coordinate)
            return
        }
        #endif

        selectedMarbleID = marble.id
        legalDestinations = destinations
        #if os(tvOS)
        focusedCoordinate = preferredDestination(from: coordinate, destinations: legalDestinations) ?? coordinate
        #else
        focusedCoordinate = coordinate
        #endif
    }

    private func clearSelection() {
        selectedMarbleID = nil
        legalDestinations = []
    }

    private func undoLastMove() {
        game.undoPlayerTurn()
        clearSelection()
    }

    private func restart(mode: GameMode) {
        game = ChineseCheckerGame(mode: mode, difficulty: game.difficulty)
        clearSelection()
        focusedCoordinate = nil
        focusCurrentPlayerIfNeeded()
    }

    #if os(tvOS)
    private func handleFocusedSelect() {
        guard let focusedCoordinate else { return }
        handleTap(focusedCoordinate)
    }

    private func handleMoveCommand(_ direction: MoveCommandDirection) {
        guard !game.computerShouldMove, game.winner == nil else { return }

        let current = focusedCoordinate ?? game.marbles.first(where: { $0.player == game.currentPlayer })?.coordinate
        guard let current else { return }

        if let next = nextCoordinate(from: current, direction: direction) {
            focusedCoordinate = next
        }
    }

    private func nextCoordinate(from current: BoardCoordinate, direction: MoveCommandDirection) -> BoardCoordinate? {
        let currentPoint = tvPoint(for: current)
        let candidates = game.board.compactMap { coordinate -> (coordinate: BoardCoordinate, score: CGFloat)? in
            guard coordinate != current else { return nil }
            let point = tvPoint(for: coordinate)
            let dx = point.x - currentPoint.x
            let dy = point.y - currentPoint.y

            let primary: CGFloat
            let secondary: CGFloat
            switch direction {
            case .left:
                guard dx < -0.1 else { return nil }
                primary = -dx
                secondary = abs(dy)
            case .right:
                guard dx > 0.1 else { return nil }
                primary = dx
                secondary = abs(dy)
            case .up:
                guard dy < -0.1 else { return nil }
                primary = -dy
                secondary = abs(dx)
            case .down:
                guard dy > 0.1 else { return nil }
                primary = dy
                secondary = abs(dx)
            @unknown default:
                return nil
            }

            return (coordinate, primary + secondary * 2.4)
        }

        return candidates.min { $0.score < $1.score }?.coordinate
    }

    private func preferredDestination(from coordinate: BoardCoordinate, destinations: Set<BoardCoordinate>) -> BoardCoordinate? {
        destinations.min {
            tvPoint(for: coordinate).distance(to: tvPoint(for: $0)) < tvPoint(for: coordinate).distance(to: tvPoint(for: $1))
        }
    }

    private func nearestCurrentPlayerMarble(to coordinate: BoardCoordinate) -> Marble? {
        game.marbles
            .filter { $0.player == game.currentPlayer && !game.legalDestinations(for: $0).isEmpty }
            .min {
                tvPoint(for: coordinate).distance(to: tvPoint(for: $0.coordinate)) < tvPoint(for: coordinate).distance(to: tvPoint(for: $1.coordinate))
            }
    }

    private func tvPoint(for coordinate: BoardCoordinate) -> CGPoint {
        let vertical = CGPoint(
            x: sqrt(3) * CGFloat(coordinate.q) + sqrt(3) / 2 * CGFloat(coordinate.r),
            y: 1.5 * CGFloat(coordinate.r)
        )
        return CGPoint(x: -vertical.y, y: vertical.x)
    }
    #endif

    private func focusCurrentPlayerIfNeeded() {
        guard !game.computerShouldMove, game.winner == nil else { return }
        if let focusedCoordinate, game.board.contains(focusedCoordinate) {
            return
        }
        focusedCoordinate = game.marbles.first {
            $0.player == game.currentPlayer && !game.legalDestinations(for: $0).isEmpty
        }?.coordinate ?? game.marbles.first(where: { $0.player == game.currentPlayer })?.coordinate
    }

    private func applyScreenshotStateIfNeeded() {
        guard !didApplyScreenshotState else { return }
        didApplyScreenshotState = true

        switch ProcessInfo.processInfo.environment["CHINESE_CHECKER_SCREENSHOT"] {
        case "hint":
            guard let marble = game.marbles.first(where: { $0.player == game.currentPlayer }) else { return }
            selectedMarbleID = marble.id
            legalDestinations = game.legalDestinations(for: marble)
            focusedCoordinate = marble.coordinate
        case "winner":
            game.prepareScreenshotWinner(.red)
        default:
            break
        }
    }
}

#Preview {
    ContentView()
}

#if os(tvOS)
private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
}
#endif
