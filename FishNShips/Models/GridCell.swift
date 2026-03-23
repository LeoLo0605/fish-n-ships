import SwiftUI

struct GridCell: Identifiable, Equatable {
    let id: Int
    let row: Int   // 0–2
    let col: Int   // 0–4
    var symbol: SlotSymbol
    var frameLevel: Int  // 0=none, 1=Seaweed, 2=Coral, 3=Shipwreck, 4=Poseidon

    init(row: Int, col: Int, symbol: SlotSymbol = .clownfish, frameLevel: Int = 0) {
        self.id = row * 5 + col
        self.row = row
        self.col = col
        self.symbol = symbol
        self.frameLevel = frameLevel
    }
}
