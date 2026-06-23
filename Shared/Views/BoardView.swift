import SwiftUI

struct BoardView: View {
    let game: ChineseCheckerGame
    let selectedMarbleID: UUID?
    let legalDestinations: Set<BoardCoordinate>
    @Binding var focusedCoordinate: BoardCoordinate?
    let onTap: (BoardCoordinate) -> Void
    @FocusState private var focusedCell: BoardCoordinate?

    var body: some View {
        GeometryReader { proxy in
            let layout = HexBoardLayout(size: proxy.size, coordinates: game.board, orientation: boardOrientation)

            ZStack {
                boardSurface
                campHaloLayer(layout: layout)
                connectorLayer(layout: layout)
                ForEach(game.board) { coordinate in
                    cell(for: coordinate, layout: layout)
                }
                glossLayer
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityElement(children: .contain)
        .onAppear {
            guard focusedCell == nil else { return }
            focusedCell = focusedCoordinate ?? game.marbles.first(where: { $0.player == game.currentPlayer })?.coordinate
        }
        .onChange(of: focusedCell) { _, newValue in
            focusedCoordinate = newValue
        }
        .onChange(of: focusedCoordinate) { _, newValue in
            guard focusedCell != newValue else { return }
            focusedCell = newValue
        }
    }

    private var boardOrientation: HexBoardOrientation {
        #if os(tvOS) || os(visionOS)
        .horizontal
        #else
        .vertical
        #endif
    }

    private var boardSurface: some View {
        ZStack {
            Image("LuxuryBoardBackground")
                .resizable()
                .clipShape(PolishedBoardShape())
        }
        .shadow(color: .black.opacity(0.42), radius: 24, y: 18)
    }

    private var woodGrain: some View {
        ZStack {
            ForEach(0..<18, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(index.isMultiple(of: 3) ? 0.10 : 0.045))
                    .frame(height: CGFloat((index % 4) + 1))
                    .rotationEffect(.degrees(Double(index % 5) - 1))
                    .offset(x: CGFloat((index % 6) - 3) * 42, y: CGFloat(index - 9) * 30)
                    .blur(radius: 2.5)
            }
        }
        .clipShape(PolishedBoardShape())
    }

    private var specularStreaks: some View {
        ZStack {
            Capsule()
                .fill(.white.opacity(0.18))
                .frame(width: 520, height: 34)
                .rotationEffect(.degrees(-18))
                .offset(x: -40, y: -170)
                .blur(radius: 16)

            Capsule()
                .fill(.white.opacity(0.10))
                .frame(width: 420, height: 18)
                .rotationEffect(.degrees(-18))
                .offset(x: 110, y: 130)
                .blur(radius: 10)
        }
        .blendMode(.screen)
        .clipShape(PolishedBoardShape())
    }

    private var glossLayer: some View {
        PolishedBoardShape()
            .fill(
                LinearGradient(
                    colors: [
                        .white.opacity(0.28),
                        .white.opacity(0.05),
                        .clear,
                        .black.opacity(0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blendMode(.screen)
        .allowsHitTesting(false)
        .padding(8)
    }

    private func campHaloLayer(layout: HexBoardLayout) -> some View {
        ZStack {
            ForEach(Array(game.blueHome), id: \.self) { coordinate in
                Circle()
                    .fill(Color(red: 0.40, green: 0.86, blue: 0.54).opacity(0.10))
                    .frame(width: layout.cellSize * 2.2, height: layout.cellSize * 2.2)
                    .blur(radius: layout.cellSize * 0.35)
                    .position(layout.point(for: coordinate))
            }

            ForEach(Array(game.redHome), id: \.self) { coordinate in
                Circle()
                    .fill(Color(red: 0.90, green: 0.10, blue: 0.08).opacity(0.10))
                    .frame(width: layout.cellSize * 2.2, height: layout.cellSize * 2.2)
                    .blur(radius: layout.cellSize * 0.35)
                    .position(layout.point(for: coordinate))
            }
        }
        .blendMode(.screen)
        .allowsHitTesting(false)
    }

    private func connectorLayer(layout: HexBoardLayout) -> some View {
        Canvas { context, _ in
            let boardSet = Set(game.board)
            var path = Path()
            let directions = [
                HexDirection(q: 1, r: 0),
                HexDirection(q: 1, r: -1),
                HexDirection(q: 0, r: -1)
            ]

            for coordinate in game.board {
                for direction in directions {
                    let next = coordinate.neighbor(in: direction)
                    guard boardSet.contains(next) else { continue }
                    let start = layout.point(for: coordinate)
                    let end = layout.point(for: next)
                    let dx = end.x - start.x
                    let dy = end.y - start.y
                    let distance = max(sqrt(dx * dx + dy * dy), 1)
                    let inset = layout.cellSize * 0.62
                    let unitX = dx / distance
                    let unitY = dy / distance
                    path.move(to: CGPoint(x: start.x + unitX * inset, y: start.y + unitY * inset))
                    path.addLine(to: CGPoint(x: end.x - unitX * inset, y: end.y - unitY * inset))
                }
            }

            context.stroke(
                path,
                with: .color(.black.opacity(0.56)),
                style: StrokeStyle(lineWidth: max(8, layout.cellSize * 0.36), lineCap: .round, lineJoin: .round)
            )
            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 1.0, green: 0.95, blue: 0.70).opacity(1.0),
                        Color(red: 0.99, green: 0.72, blue: 0.28).opacity(1.0),
                        Color(red: 0.72, green: 0.34, blue: 0.08).opacity(0.96)
                    ]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: layout.size.width, y: layout.size.height)
                ),
                style: StrokeStyle(lineWidth: max(5.4, layout.cellSize * 0.205), lineCap: .round, lineJoin: .round)
            )
            context.stroke(
                path,
                with: .color(.white.opacity(0.42)),
                style: StrokeStyle(lineWidth: max(1.5, layout.cellSize * 0.060), lineCap: .round, lineJoin: .round)
            )
        }
        .allowsHitTesting(false)
    }

    private func cell(for coordinate: BoardCoordinate, layout: HexBoardLayout) -> some View {
        let marble = game.marble(at: coordinate)
        let isDestination = legalDestinations.contains(coordinate)
        let isHome = game.redHome.contains(coordinate) || game.blueHome.contains(coordinate)
        let isFocused = focusedCoordinate == coordinate
        let isSelected = isSelected(marble: marble, coordinate: coordinate, isFocused: isFocused)

        return Button {
            onTap(coordinate)
        } label: {
            ZStack {
                socketView(size: layout.cellSize, isDestination: isDestination, isHome: isHome)

                if let marble {
                    marbleView(for: marble.player, isSelected: isSelected, size: layout.cellSize)
                }

                focusRing(size: layout.cellSize, isFocused: isFocused)
            }
        }
        #if os(tvOS)
        .buttonStyle(BoardCellButtonStyle())
        #else
        .buttonStyle(.plain)
        #endif
        .focusable(true)
        .focused($focusedCell, equals: coordinate)
        #if os(tvOS)
        .focusEffectDisabled()
        #endif
        .frame(width: layout.cellSize, height: layout.cellSize)
        .position(layout.point(for: coordinate))
        .accessibilityLabel(accessibilityLabel(for: coordinate, marble: marble, isDestination: isDestination))
        .accessibilityIdentifier("cell_\(coordinate.q)_\(coordinate.r)")
        .accessibilityHint(accessibilityHint(for: marble, isDestination: isDestination))
    }

    private func isSelected(marble: Marble?, coordinate: BoardCoordinate, isFocused: Bool) -> Bool {
        guard marble?.id == selectedMarbleID else { return false }
        #if os(tvOS)
        return false
        #else
        return true
        #endif
    }

    private func socketView(size: CGFloat, isDestination: Bool, isHome: Bool) -> some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.44))
                .frame(width: size * 1.48, height: size * 0.75)
                .offset(x: size * 0.05, y: size * 0.19)
                .blur(radius: 3.6)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.86, blue: 0.48),
                            Color(red: 0.95, green: 0.58, blue: 0.18),
                            Color(red: 0.36, green: 0.15, blue: 0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 1.42, height: size * 1.42)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.82),
                            Color(red: 1.0, green: 0.70, blue: 0.24).opacity(0.74),
                            .black.opacity(0.52)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(2.0, size * 0.07)
                )
                .frame(width: size * 1.42, height: size * 1.42)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.23, green: 0.10, blue: 0.035).opacity(0.98),
                            Color(red: 0.055, green: 0.025, blue: 0.010).opacity(0.99),
                            .black.opacity(1.0)
                        ],
                        center: UnitPoint(x: 0.38, y: 0.30),
                        startRadius: 0,
                        endRadius: size * 0.36
                    )
                )
                .frame(width: size * 1.12, height: size * 1.12)

            Circle()
                .stroke(.black.opacity(0.64), lineWidth: max(2.0, size * 0.08))
                .frame(width: size * 1.12, height: size * 1.12)
                .offset(y: size * 0.015)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .black.opacity(0.05),
                            .black.opacity(0.45),
                            .black.opacity(0.88)
                        ],
                        center: UnitPoint(x: 0.48, y: 0.55),
                        startRadius: size * 0.07,
                        endRadius: size * 0.34
                    )
                )
                .frame(width: size * 0.96, height: size * 0.96)

            Circle()
                .trim(from: 0.04, to: 0.34)
                .stroke(.white.opacity(0.78), style: StrokeStyle(lineWidth: max(1.0, size * 0.040), lineCap: .round))
                .frame(width: size * 1.34, height: size * 1.34)
                .rotationEffect(.degrees(-28))

            Ellipse()
                .fill(.white.opacity(0.32))
                .frame(width: size * 0.23, height: size * 0.065)
                .offset(x: -size * 0.14, y: -size * 0.19)
                .rotationEffect(.degrees(-22))
                .blur(radius: 0.7)

            if isDestination {
                legalDestinationRing(size: size)
            }
        }
        .frame(width: size, height: size)
    }

    private func legalDestinationRing(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.18, green: 1.0, blue: 0.80).opacity(0.20))
                .frame(width: size * 1.42, height: size * 1.42)
                .blur(radius: 1.4)

            Circle()
                .stroke(Color(red: 0.18, green: 1.0, blue: 0.82).opacity(0.98), lineWidth: max(3, size * 0.10))
                .frame(width: size * 1.56, height: size * 1.56)

            Circle()
                .stroke(.white.opacity(0.88), lineWidth: max(1.2, size * 0.035))
                .frame(width: size * 1.28, height: size * 1.28)
        }
        .shadow(color: Color(red: 0.18, green: 1.0, blue: 0.82).opacity(0.85), radius: 8)
        .allowsHitTesting(false)
    }

    private func focusRing(size: CGFloat, isFocused: Bool) -> some View {
        Circle()
            .stroke(.white.opacity(isFocused ? 0.98 : 0), lineWidth: max(3, size * 0.10))
            .frame(width: size * 1.66, height: size * 1.66)
            .overlay {
                Circle()
                    .stroke(Color(red: 0.26, green: 0.95, blue: 0.88).opacity(isFocused ? 0.90 : 0), lineWidth: max(1.8, size * 0.045))
                    .frame(width: size * 1.84, height: size * 1.84)
            }
            .shadow(color: .white.opacity(isFocused ? 0.75 : 0), radius: isFocused ? 8 : 0)
            .animation(.easeOut(duration: 0.16), value: isFocused)
            .allowsHitTesting(false)
    }

    private func socketRimColor(isDestination: Bool, isHome: Bool) -> Color {
        if isDestination {
            return Color(red: 0.25, green: 0.86, blue: 0.66)
        }
        return Color(red: 0.92, green: 0.55, blue: 0.18)
    }

    private func marbleView(for player: Player, isSelected: Bool, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.56))
                .frame(width: size * 1.58, height: size * 0.64)
                .offset(x: size * 0.06, y: size * 0.31)
                .blur(radius: 4.2)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.88, blue: 0.52),
                            Color(red: 0.82, green: 0.44, blue: 0.11),
                            Color(red: 0.24, green: 0.10, blue: 0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 1.54, height: size * 1.54)
                .offset(y: size * 0.055)

            Circle()
                .fill(.black.opacity(0.28))
                .frame(width: size * 1.36, height: size * 1.36)
                .offset(y: size * 0.065)
                .blur(radius: 1.2)

            Circle()
                .fill(marbleFill(for: player))
                .frame(width: size * 1.44, height: size * 1.44)
                .offset(y: -size * 0.015)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.92), .white.opacity(0.30), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size * 0.54
                    )
                )
                .frame(width: size * 1.44, height: size * 1.44)
                .offset(y: -size * 0.015)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.clear, .clear, .black.opacity(0.42)],
                        center: UnitPoint(x: 0.36, y: 0.30),
                        startRadius: size * 0.10,
                        endRadius: size * 0.45
                    )
                )
                .frame(width: size * 1.44, height: size * 1.44)
                .offset(y: -size * 0.015)

            Capsule()
                .fill(marbleRibbon(for: player))
                .frame(width: size * 0.115, height: size * 0.64)
                .rotationEffect(.degrees(player == .red ? 34 : -28))
                .offset(x: player == .red ? size * 0.04 : -size * 0.02)
                .blur(radius: 0.9)
                .clipShape(Circle())
                .frame(width: size * 1.44, height: size * 1.44)
                .offset(y: -size * 0.015)

            Capsule()
                .fill(.white.opacity(0.30))
                .frame(width: size * 0.060, height: size * 0.48)
                .rotationEffect(.degrees(player == .red ? -32 : 26))
                .offset(x: player == .red ? -size * 0.08 : size * 0.08)
                .blur(radius: 0.8)
                .clipShape(Circle())
                .frame(width: size * 1.44, height: size * 1.44)
                .offset(y: -size * 0.015)

            gemstoneFacetLines(for: player, size: size)
                .clipShape(Circle())
                .frame(width: size * 1.44, height: size * 1.44)
                .offset(y: -size * 0.015)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.96),
                            .white.opacity(0.36),
                            .black.opacity(0.30)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isSelected ? max(3, size * 0.095) : max(1.2, size * 0.035)
                )
                .frame(width: size * 1.44, height: size * 1.44)
                .offset(y: -size * 0.015)

            Circle()
                .stroke(isSelected ? .yellow.opacity(0.95) : .clear, lineWidth: isSelected ? max(2, size * 0.055) : 0)
                .frame(width: size * 1.58, height: size * 1.58)
                .padding(size * -0.02)

            Ellipse()
                .fill(.white.opacity(0.88))
                .frame(width: size * 0.30, height: size * 0.15)
                .offset(x: -size * 0.17, y: -size * 0.24)
                .blur(radius: 1.2)

            Circle()
                .fill(.white.opacity(0.66))
                .frame(width: size * 0.065, height: size * 0.065)
                .offset(x: size * 0.21, y: -size * 0.12)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.60), radius: isSelected ? 9 : 5, y: 4)
    }

    private func gemstoneFacetLines(for player: Player, size: CGFloat) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(facetColor(for: player, index: index))
                    .frame(width: size * 0.045, height: size * CGFloat(0.30 + Double(index) * 0.08))
                    .rotationEffect(.degrees(player == .red ? Double(24 + index * 22) : Double(-20 - index * 18)))
                    .offset(
                        x: size * CGFloat(-0.14 + Double(index) * 0.14),
                        y: size * CGFloat(-0.02 + Double(index % 2) * 0.08)
                    )
                    .blur(radius: 0.45)
            }
        }
        .frame(width: size * 0.74, height: size * 0.74)
    }

    private func marbleFill(for player: Player) -> some ShapeStyle {
        switch player {
        case .red:
            AnyShapeStyle(
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.62, blue: 0.52),
                        Color(red: 0.96, green: 0.07, blue: 0.03),
                        Color(red: 0.54, green: 0.00, blue: 0.015),
                        Color(red: 0.18, green: 0.00, blue: 0.005)
                    ],
                    center: .topLeading,
                    startRadius: 2,
                    endRadius: 36
                )
            )
        case .blue:
            AnyShapeStyle(
                RadialGradient(
                    colors: [
                        Color(red: 0.84, green: 1.0, blue: 0.86),
                        Color(red: 0.26, green: 0.76, blue: 0.42),
                        Color(red: 0.08, green: 0.42, blue: 0.22),
                        Color(red: 0.02, green: 0.16, blue: 0.09)
                    ],
                    center: .topLeading,
                    startRadius: 2,
                    endRadius: 36
                )
            )
        }
    }

    private func marbleRibbon(for player: Player) -> some ShapeStyle {
        switch player {
        case .red:
            AnyShapeStyle(Color(red: 0.38, green: 0.0, blue: 0.0).opacity(0.52))
        case .blue:
            AnyShapeStyle(Color(red: 0.05, green: 0.28, blue: 0.15).opacity(0.45))
        }
    }

    private func facetColor(for player: Player, index: Int) -> Color {
        switch player {
        case .red:
            return [
                Color(red: 1.0, green: 0.28, blue: 0.18).opacity(0.24),
                Color(red: 0.36, green: 0.0, blue: 0.0).opacity(0.36),
                Color(red: 1.0, green: 0.74, blue: 0.66).opacity(0.18)
            ][index]
        case .blue:
            return [
                Color(red: 0.78, green: 1.0, blue: 0.80).opacity(0.28),
                Color(red: 0.04, green: 0.30, blue: 0.16).opacity(0.34),
                Color(red: 0.94, green: 1.0, blue: 0.86).opacity(0.20)
            ][index]
        }
    }

    private func accessibilityLabel(for coordinate: BoardCoordinate, marble: Marble?, isDestination: Bool) -> String {
        if let marble {
            return "\(marble.player.displayName) marble at \(coordinate.q), \(coordinate.r)"
        }
        if isDestination {
            return "Legal destination at \(coordinate.q), \(coordinate.r)"
        }
        return "Empty cell at \(coordinate.q), \(coordinate.r)"
    }

    private func accessibilityHint(for marble: Marble?, isDestination: Bool) -> String {
        if isDestination {
            return "Move the selected marble here"
        }
        if marble != nil {
            return "Select this marble"
        }
        return "Empty board cell"
    }
}

enum HexBoardOrientation {
    case vertical
    case horizontal
}

struct HexBoardLayout {
    let size: CGSize
    let coordinates: [BoardCoordinate]
    let orientation: HexBoardOrientation

    var cellSize: CGFloat {
        max(16, scale * 0.78)
    }

    private var hexSize: CGFloat {
        scale * 0.46
    }

    private var scale: CGFloat {
        let bounds = rawBounds
        let availableWidth = size.width * (orientation == .horizontal ? 0.74 : 0.84)
        let availableHeight = size.height * (orientation == .horizontal ? 0.72 : 0.66)
        return min(availableWidth / max(bounds.width, 1), availableHeight / max(bounds.height, 1))
    }

    private var rawBounds: CGRect {
        guard let first = coordinates.first else { return .zero }
        return coordinates.dropFirst().reduce(CGRect(origin: rawPoint(for: first), size: .zero)) { partial, coordinate in
            partial.union(CGRect(origin: rawPoint(for: coordinate), size: .zero))
        }.insetBy(dx: -1.2, dy: -1.2)
    }

    func point(for coordinate: BoardCoordinate) -> CGPoint {
        let bounds = rawBounds
        let raw = rawPoint(for: coordinate)
        let normalizedX = raw.x - bounds.midX
        let normalizedY = raw.y - bounds.midY
        return CGPoint(
            x: size.width / 2 + normalizedX * scale,
            y: size.height / 2 + normalizedY * scale - size.height * 0.035
        )
    }

    private func rawPoint(for coordinate: BoardCoordinate) -> CGPoint {
        let point = CGPoint(
            x: sqrt(3) * CGFloat(coordinate.q) + sqrt(3) / 2 * CGFloat(coordinate.r),
            y: 1.5 * CGFloat(coordinate.r)
        )
        switch orientation {
        case .vertical:
            return point
        case .horizontal:
            return CGPoint(x: -point.y, y: point.x)
        }
    }
}

struct PolishedBoardShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cut = min(rect.width, rect.height) * 0.13
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.14))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.09))
        path.addLine(to: CGPoint(x: rect.maxX - cut * 0.86, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cut * 0.86, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.09))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.14))
        path.closeSubpath()
        return path
    }
}

#if os(tvOS)
private struct BoardCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
    }
}
#endif
