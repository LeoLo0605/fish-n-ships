import SpriteKit

final class GameScene: SKScene {

    // MARK: - Layout constants

    private enum Layout {
        static let cellSize: CGFloat = ReelNode.cellSize
        static let gap: CGFloat = ReelNode.gap
        static let stride: CGFloat = ReelNode.stride          // 68 pt
        static let gridWidth: CGFloat = stride * 5 - gap      // 336 pt
        static let gridHeight: CGFloat = stride * 3 - gap     // 200 pt
        static let colStagger: TimeInterval = 0.15
    }

    // MARK: - State

    weak var viewModel: GameViewModel?
    private var reelNodes: [ReelNode] = []

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.016, green: 0.051, blue: 0.098, alpha: 1) // #040D19
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
    }

    private func buildGrid(initialGrid: [GridCell]? = nil) {
        reelNodes.removeAll()
        removeAllChildren()

        // Background
        let bg = SKSpriteNode(color: .black, size: self.size)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.zPosition = -1
        addChild(bg)

        // Grid container — centred in scene
        let container = SKNode()
        container.position = CGPoint(
            x: (size.width - Layout.gridWidth) / 2 + Layout.cellSize / 2,
            y: (size.height + Layout.gridHeight) / 2 - Layout.cellSize / 2
        )
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
            let delay = Double(col) * Layout.colStagger
            let syms = finalSymbolsByCol[col]
            reel.spinAnimation(finalSymbols: syms, delay: delay) { [weak self] in
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
}
