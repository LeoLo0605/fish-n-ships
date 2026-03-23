import SpriteKit

/// A single grid cell. M1: coloured square. M2+: cropped texture from GameSpriteSheet.
final class SymbolNode: SKSpriteNode {

    static let cellSize = CGSize(width: 64, height: 64)

    private(set) var symbol: SlotSymbol

    init(symbol: SlotSymbol) {
        self.symbol = symbol
        super.init(texture: nil, color: symbol.placeholderUIColor, size: SymbolNode.cellSize)
        configure(symbol: symbol, useTexture: false)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("not used") }

    /// Call to update this node's symbol.
    /// - Parameters:
    ///   - symbol: The new symbol to display.
    ///   - useTexture: false (M1) = solid colour square. true (M2+) = cropped spritesheet texture.
    func configure(symbol: SlotSymbol, useTexture: Bool = false) {
        self.symbol = symbol
        if useTexture {
            // M2+: texture = SymbolCrop.texture(for: symbol)
            // Crop constants (normalised rects) to be measured from GameSpriteSheet in M2.
        } else {
            texture = nil
            color = symbol.placeholderUIColor
            colorBlendFactor = 1.0
        }
    }
}
