import Foundation

/// A single winning combination: one symbol matched across consecutive columns.
struct SymbolWin: Equatable {
    let symbol: SlotSymbol
    let matchCount: Int        // 3, 4, or 5
    let multiplier: Double     // from PayTable
    let payout: Double         // multiplier × bet
    let cells: Set<Int>        // GridCell.id values that contributed
}

/// Complete result of evaluating one spin.
struct WinResult: Equatable {
    let symbolWins: [SymbolWin]
    let scatterCount: Int
    let scatterPayout: Double
    let totalPayout: Double    // sum of all symbolWin payouts + scatterPayout
    let winningCells: Set<Int> // union of all contributing cell IDs

    /// Convenience: true if anything was won.
    var hasWin: Bool { totalPayout > 0 }

    /// Empty result for no-win spins.
    static let none = WinResult(
        symbolWins: [], scatterCount: 0, scatterPayout: 0,
        totalPayout: 0, winningCells: []
    )
}
