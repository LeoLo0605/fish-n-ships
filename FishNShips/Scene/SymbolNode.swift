import SpriteKit

/// A single grid cell. M1: coloured square. M2+: named texture from Assets.xcassets.
final class SymbolNode: SKSpriteNode {

    static let cellSize = CGSize(width: 64, height: 64)

    private(set) var symbol: SlotSymbol

    init(symbol: SlotSymbol) {
        self.symbol = symbol
        super.init(texture: nil, color: symbol.placeholderUIColor, size: SymbolNode.cellSize)
        configure(symbol: symbol)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("not used") }

    /// Call to update this node's symbol.
    /// - Parameters:
    ///   - symbol: The new symbol to display.
    ///   - useTexture: true (M2+) = named texture. false = solid colour placeholder.
    func configure(symbol: SlotSymbol, useTexture: Bool = true) {
        self.symbol = symbol
        if useTexture {
            texture = SKTexture(imageNamed: symbol.imageName)
            colorBlendFactor = 0
            size = SymbolNode.cellSize
        } else {
            texture = nil
            color = symbol.placeholderUIColor
            colorBlendFactor = 1.0
        }
    }
}
