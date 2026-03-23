import SwiftUI

struct ReelGrid {
    var cells: [GridCell]   // count == 15, row-major

    init() {
        cells = (0..<3).flatMap { row in
            (0..<5).map { col in
                GridCell(row: row, col: col, symbol: ReelGrid.weightedRandom())
            }
        }
    }

    mutating func randomise() {
        for i in cells.indices {
            cells[i].symbol = ReelGrid.weightedRandom()
            // frameLevel intentionally preserved
        }
    }

    func cell(row: Int, col: Int) -> GridCell {
        cells[row * 5 + col]
    }

    static func weightedRandom() -> SlotSymbol {
        let total = SlotSymbol.allCases.reduce(0) { $0 + $1.weight }
        var r = Int.random(in: 0..<total)
        for sym in SlotSymbol.allCases {
            r -= sym.weight
            if r < 0 { return sym }
        }
        return .clownfish  // fallback (unreachable)
    }
}
