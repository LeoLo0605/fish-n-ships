import SpriteKit

/// One column of the reel grid (3 SymbolNodes). Handles its own spin animation.
final class ReelNode: SKCropNode {

    static let cellSize: CGFloat = 64
    static let gap: CGFloat = 4
    static let stride: CGFloat = cellSize + gap  // 68 pt
    static let rowInterval: CGFloat = 0.15        // seconds per row scroll

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
    ///   - delay: Stagger delay before this reel starts.
    ///   - spinDuration: Total scroll time. Must equal (N + 0.5) × rowInterval where N ≡ 3 mod 4
    ///     (N = 7, 11, 15, …) so the last 3 wraps land on node2 → node1 → node0 in order.
    ///   - completion: Called when the animation finishes.
    func spinAnimation(finalSymbols: [SlotSymbol], delay: TimeInterval, spinDuration: TimeInterval, completion: @escaping () -> Void) {
        let scrollSpeed: CGFloat = ReelNode.stride / ReelNode.rowInterval

        // Compute how many node-wraps occur during spinDuration.
        // Wraps happen at total scroll: stride/2, 3·stride/2, 5·stride/2, …
        // wrapCount = number of those thresholds strictly less than totalScroll.
        let totalScroll = CGFloat(spinDuration) * scrollSpeed
        let wrapCount = Int((totalScroll - ReelNode.stride / 2) / ReelNode.stride)

        // Symbol queue: queue[0] initialises the buffer node; queue[k] is assigned on the k-th wrap.
        // The last 3 wraps (indices wrapCount-2, wrapCount-1, wrapCount) target node2, node1, node0.
        // All earlier wraps receive random symbols.
        var symbolQueue = (0..<(wrapCount - 2)).map { _ in SlotSymbol.allCases.randomElement()! }
        symbolQueue += [finalSymbols[2], finalSymbols[1], finalSymbols[0]]
        var queueIdx = 0

        // Add a buffer node above the visible window so the strip is always full.
        let buffer = SymbolNode(symbol: symbolQueue[queueIdx])
        queueIdx += 1
        buffer.position = CGPoint(x: 0, y: ReelNode.stride * 2)
        addChild(buffer)

        // 4-node strip: 3 visible (symbolNodes) + 1 above the crop window (buffer).
        let nodes: [SymbolNode] = symbolNodes + [buffer]
        var scrolled: CGFloat = 0
        let bottomCut: CGFloat = -ReelNode.stride * 1.5

        // Per-frame scroll: moves nodes down by delta, wraps the single lowest node that exits bottom.
        let scrollAction = SKAction.customAction(withDuration: spinDuration) { _, elapsed in
            let target = elapsed * scrollSpeed
            let delta = target - scrolled
            guard delta > 0 else { return }
            scrolled = target

            nodes.forEach { $0.position.y -= delta }

            // Only wrap one node per frame to preserve queue ordering.
            if let lowest = nodes.filter({ $0.position.y < bottomCut }).min(by: { $0.position.y < $1.position.y }) {
                let topY = nodes.max(by: { $0.position.y < $1.position.y })?.position.y ?? 0
                lowest.position = CGPoint(x: 0, y: topY + ReelNode.stride)
                let sym = queueIdx < symbolQueue.count ? symbolQueue[queueIdx] : SlotSymbol.allCases.randomElement()!
                queueIdx += 1
                lowest.configure(symbol: sym)
            }
        }

        let sequence = SKAction.sequence([
            SKAction.wait(forDuration: delay),
            scrollAction,
            SKAction.run { [weak self] in
                guard let self else { return }
                buffer.removeFromParent()
                // Snap positions only — symbols are already correct from the queue.
                for i in 0..<3 {
                    self.symbolNodes[i].position = CGPoint(x: 0, y: CGFloat(1 - i) * ReelNode.stride)
                }
            },
            SKAction.scale(to: 1.06, duration: 0.05),
            SKAction.scale(to: 1.0,  duration: 0.07),
            SKAction.run { completion() }
        ])

        run(sequence, withKey: "spin-col-\(column)")
    }
}
