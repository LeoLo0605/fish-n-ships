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
    /// - Parameters:
    ///   - finalSymbols: The 3 symbols to snap to at the end (top→bottom).
    ///   - delay: Stagger delay before this reel starts (col * 0.15 s).
    ///   - completion: Called when the animation finishes.
    func spinAnimation(finalSymbols: [SlotSymbol], delay: TimeInterval, completion: @escaping () -> Void) {
        let cycleColors = SlotSymbol.allCases.map { $0.placeholderUIColor }
        var colorIndex = 0
        let cycleKey = "spin-cycle-\(column)"

        // Main sequence — cycle is run separately so it can be stopped independently
        let sequence = SKAction.sequence([
            // Wait for stagger
            SKAction.wait(forDuration: delay),
            // Start color-cycling on a separate action key
            SKAction.run { [weak self] in
                guard let self else { return }
                let cycle = SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.run { [weak self] in
                            colorIndex = (colorIndex + 1) % cycleColors.count
                            self?.symbolNodes.forEach {
                                $0.color = cycleColors[colorIndex]
                                $0.colorBlendFactor = 1.0
                            }
                        },
                        SKAction.wait(forDuration: 0.06)
                    ])
                )
                self.run(cycle, withKey: cycleKey)
            },
            // Fast cycling phase (0.9 s)
            SKAction.wait(forDuration: 0.9),
            // Stop cycle and snap to final symbols (useTexture: true reveals sprites)
            SKAction.run { [weak self] in
                self?.removeAction(forKey: cycleKey)
                self?.updateSymbols(finalSymbols)
            },
            // Bounce: scale up slightly then back
            SKAction.scale(to: 1.06, duration: 0.05),
            SKAction.scale(to: 1.0,  duration: 0.07),
            // Signal done
            SKAction.run { completion() }
        ])

        run(sequence, withKey: "spin-col-\(column)")
    }
}
