import SpriteKit

/// One column of the reel grid (3 SymbolNodes). Handles its own spin animation.
final class ReelNode: SKCropNode {

    static let cellSize: CGFloat = 64
    static let gap: CGFloat = 4
    static let stride: CGFloat = cellSize + gap  // 68 pt

    private var symbolNodes: [SymbolNode] = []
    let column: Int

    init(column: Int, symbols: [SlotSymbol]) {
        self.column = column
        super.init()

        // Crop mask — window exactly tall enough for 3 rows
        let maskHeight = ReelNode.cellSize * 3 + ReelNode.gap * 2
        let mask = SKSpriteNode(color: .white,
                                size: CGSize(width: ReelNode.cellSize, height: maskHeight))
        maskNode = mask

        // Build 3 SymbolNodes. Row 0 = top (positive y), row 2 = bottom.
        for row in 0..<3 {
            let node = SymbolNode(symbol: symbols[row])
            node.position = CGPoint(x: 0, y: CGFloat(1 - row) * ReelNode.stride)
            addChild(node)
            symbolNodes.append(node)
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("not used") }

    // MARK: - Symbol Update

    func updateSymbols(_ symbols: [SlotSymbol], useTexture: Bool = true) {
        for (i, sym) in symbols.prefix(3).enumerated() {
            symbolNodes[i].configure(symbol: sym, useTexture: useTexture)
        }
    }

    // MARK: - Spin Animation

    /// Plays the spin animation for this reel.
    /// Symbols scroll downward continuously (slot-machine reel effect), then snap to final symbols.
    /// - Parameters:
    ///   - finalSymbols: The 3 symbols to display at rest (top→bottom).
    ///   - delay: Stagger delay before this reel starts (col * 0.15 s).
    ///   - completion: Called when the animation finishes.
    func spinAnimation(finalSymbols: [SlotSymbol], delay: TimeInterval, completion: @escaping () -> Void) {
        let spinDuration: TimeInterval = 0.9
        // Scroll speed: 1 row (stride) per 0.12 s.
        let scrollSpeed: CGFloat = ReelNode.stride / 0.12

        // Add a buffer node above the visible window so the strip is always full
        // while symbols scroll down and wrap around.
        let buffer = SymbolNode(symbol: SlotSymbol.allCases.randomElement()!)
        buffer.position = CGPoint(x: 0, y: ReelNode.stride * 2)
        addChild(buffer)

        // 4-node strip: 3 visible (symbolNodes) + 1 above the crop window (buffer).
        let nodes: [SymbolNode] = symbolNodes + [buffer]
        var scrolled: CGFloat = 0
        // Nodes below this threshold are outside the crop window bottom and need wrapping.
        let bottomCut: CGFloat = -ReelNode.stride * 1.5

        // Per-frame scroll: moves nodes down by delta, wraps any that exit the bottom.
        let scrollAction = SKAction.customAction(withDuration: spinDuration) { _, elapsed in
            let target = elapsed * scrollSpeed
            let delta = target - scrolled
            guard delta > 0 else { return }
            scrolled = target

            nodes.forEach { $0.position.y -= delta }

            for node in nodes where node.position.y < bottomCut {
                let topY = nodes.max(by: { $0.position.y < $1.position.y })?.position.y ?? 0
                node.position = CGPoint(x: 0, y: topY + ReelNode.stride)
                node.configure(symbol: SlotSymbol.allCases.randomElement()!)
            }
        }

        let sequence = SKAction.sequence([
            SKAction.wait(forDuration: delay),
            scrollAction,
            SKAction.run { [weak self] in
                guard let self else { return }
                buffer.removeFromParent()
                // Reset the 3 visible nodes to canonical positions with final symbols.
                for (i, sym) in finalSymbols.prefix(3).enumerated() {
                    self.symbolNodes[i].position = CGPoint(x: 0, y: CGFloat(1 - i) * ReelNode.stride)
                    self.symbolNodes[i].configure(symbol: sym)
                }
            },
            SKAction.scale(to: 1.06, duration: 0.05),
            SKAction.scale(to: 1.0,  duration: 0.07),
            SKAction.run { completion() }
        ])

        run(sequence, withKey: "spin-col-\(column)")
    }
}
