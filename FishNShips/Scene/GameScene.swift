import SpriteKit

final class GameScene: SKScene {

    // MARK: - Layout constants

    private enum Layout {
        static let cellSize: CGFloat = ReelNode.cellSize
        static let gap: CGFloat = ReelNode.gap
        static let stride: CGFloat = ReelNode.stride          // 68 pt
        static let gridWidth: CGFloat = stride * 5 - gap      // 336 pt
        static let gridHeight: CGFloat = stride * 3 - gap     // 200 pt
        /// Base spin duration for col 0. Must be (N + 0.5) × rowInterval, N ≡ 3 mod 4.
        static let baseSpinDuration: TimeInterval = 7.5 * Double(ReelNode.rowInterval)  // N = 7
        /// Extra spin time added per column. Must be a multiple of 4 × rowInterval (= 1.6 s)
        /// so wrapCount stays ≡ 3 mod 4 and finals always land on the correct nodes.
        static let colStopStagger: TimeInterval = 4 * Double(ReelNode.rowInterval) // 1.6 s
    }

    // MARK: - State

    weak var viewModel: GameViewModel?
    private var reelNodes: [ReelNode] = []
    private var gridContainer: SKNode?

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.016, green: 0.051, blue: 0.098, alpha: 1) // #040D19
        // Origin at scene centre — grid position is size-independent.
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        // buildGrid is called from configure(with:) so it has access to initial symbols.
        // If viewModel is already set (unlikely at this point), wire immediately.
        if let vm = viewModel { configure(with: vm) } else { buildGrid() }
    }

    // MARK: - Setup

    /// Wire the ViewModel. Called from GameView.onAppear — the guaranteed-safe wiring point.
    func configure(with vm: GameViewModel) {
        viewModel = vm
        buildGrid(initialGrid: vm.grid)   // rebuild with ViewModel's initial symbols
        vm.onSpinRequested = { [weak self] in
            guard let self else { return }
            self.startSpinAnimation()
        }
        vm.onWinHighlight = { [weak self] cellIndices in
            guard let self else { return }
            self.highlightWinningCells(cellIndices)
        }
    }

    private func buildGrid(initialGrid: [GridCell]? = nil) {
        reelNodes.removeAll()
        removeAllChildren()
        gridContainer = nil

        // Grid container — origin is scene centre (anchorPoint 0.5, 0.5), so this is size-independent.
        // Row 0 (top) at y = +(gridHeight - cellSize)/2, columns grow rightward from x = -(gridWidth - cellSize)/2.
        let container = SKNode()
        container.position = CGPoint(
            x: -(Layout.gridWidth  - Layout.cellSize) / 2,   // left-align columns from centre
            y:  (Layout.gridHeight - Layout.cellSize) / 2    // top row above centre
        )
        gridContainer = container
        addChild(container)

        // Build 5 ReelNodes — use ViewModel's initial grid if available, else random
        let fallback = ReelGrid()
        for col in 0..<5 {
            let symbols: [SlotSymbol]
            if let grid = initialGrid {
                // grid is row-major; extract this column's symbols top→bottom
                symbols = (0..<3).map { row in grid[row * 5 + col].symbol }
            } else {
                symbols = (0..<3).map { _ in fallback.cell(row: 0, col: col).symbol }
            }
            let reel = ReelNode(column: col, symbols: symbols)
            reel.position = CGPoint(x: CGFloat(col) * Layout.stride, y: 0)
            container.addChild(reel)
            reelNodes.append(reel)
        }
    }

    // MARK: - Animation

    func startSpinAnimation() {
        guard let vm = viewModel else { return }

        // Extract per-column final symbols from the already-randomised grid
        var finalSymbolsByCol: [[SlotSymbol]] = Array(repeating: [], count: 5)
        for cell in vm.grid {
            finalSymbolsByCol[cell.col].append(cell.symbol)
        }

        var completedReels = 0
        let totalReels = reelNodes.count

        for (col, reel) in reelNodes.enumerated() {
            let spinDuration = Layout.baseSpinDuration + Double(col) * Layout.colStopStagger
            let syms = finalSymbolsByCol[col]
            reel.spinAnimation(finalSymbols: syms, delay: 0, spinDuration: spinDuration) { [weak self] in
                completedReels += 1
                if completedReels == totalReels {
                    self?.animationDidFinish()
                }
            }
        }
    }

    private func animationDidFinish() {
        viewModel?.spinCompleted()
    }

    // MARK: - Win Highlight

    func highlightWinningCells(_ cellIndices: Set<Int>) {
        var winningNodes: [SymbolNode] = []
        var nonWinningNodes: [SymbolNode] = []

        for col in 0..<5 {
            for row in 0..<3 {
                let idx = row * 5 + col
                let node = reelNodes[col].symbolNodes[row]
                if cellIndices.contains(idx) {
                    winningNodes.append(node)
                } else {
                    nonWinningNodes.append(node)
                }
            }
        }

        for node in nonWinningNodes {
            node.run(SKAction.fadeAlpha(to: 0.4, duration: 0.1))
        }

        guard !winningNodes.isEmpty else {
            viewModel?.winHighlightCompleted()
            return
        }

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.15),
            SKAction.scale(to: 1.0,  duration: 0.15)
        ])

        for (i, node) in winningNodes.enumerated() {
            if i == winningNodes.count - 1 {
                node.run(pulse) { [weak self] in
                    for n in nonWinningNodes { n.alpha = 1.0 }
                    self?.viewModel?.winHighlightCompleted()
                }
            } else {
                node.run(pulse)
            }
        }
    }
}
