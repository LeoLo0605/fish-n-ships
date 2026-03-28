import Foundation

struct WinEngine {

    /// Evaluate the grid for 243-ways symbol wins and scatter (Pearl) wins.
    /// - Parameters:
    ///   - grid: 15 GridCells in row-major order (row * 5 + col).
    ///   - bet: Current bet amount.
    /// - Returns: A WinResult with all wins, payouts, and winning cell indices.
    static func evaluate(grid: [GridCell], bet: Double) -> WinResult {
        let symbolWins = evaluateSymbolWins(grid: grid, bet: bet)
        let (scatterCount, scatterPayout, scatterCells) = evaluateScatter(grid: grid, bet: bet)

        let symbolPayout = symbolWins.reduce(0.0) { $0 + $1.payout }
        let totalPayout = symbolPayout + scatterPayout

        var allCells = Set<Int>()
        for win in symbolWins { allCells.formUnion(win.cells) }
        allCells.formUnion(scatterCells)

        return WinResult(
            symbolWins: symbolWins,
            scatterCount: scatterCount,
            scatterPayout: scatterPayout,
            totalPayout: totalPayout,
            winningCells: allCells
        )
    }

    // MARK: - 243-ways detection

    /// Check each regular symbol for left-to-right consecutive column matches.
    private static func evaluateSymbolWins(grid: [GridCell], bet: Double) -> [SymbolWin] {
        // Build column sets: for each column, the set of symbols present + whether Wild is present.
        let columns: [(symbols: Set<SlotSymbol>, hasWild: Bool, cells: [GridCell])] = (0..<5).map { col in
            let colCells = (0..<3).map { row in grid[row * 5 + col] }
            let syms = Set(colCells.map { $0.symbol })
            return (syms, syms.contains(.wild), colCells)
        }

        // Regular symbols to check (all except Wild and Pearl).
        let regulars = SlotSymbol.allCases.filter { $0 != .wild && $0 != .pearl }
        var wins: [SymbolWin] = []

        for symbol in regulars {
            var matchCount = 0
            var contributingCells = Set<Int>()
            var hasRegularSymbol = false

            for col in 0..<5 {
                let colData = columns[col]
                let symbolPresent = colData.symbols.contains(symbol)
                let wildPresent = colData.hasWild

                if symbolPresent || wildPresent {
                    matchCount += 1
                    if symbolPresent { hasRegularSymbol = true }
                    // Add all cells in this column that are the symbol or Wild.
                    for cell in colData.cells where cell.symbol == symbol || cell.symbol == .wild {
                        contributingCells.insert(cell.id)
                    }
                } else {
                    break
                }
            }

            // Must have ≥ 3 consecutive columns AND at least one actual (non-Wild) symbol.
            guard matchCount >= 3, hasRegularSymbol else { continue }
            guard let multiplier = PayTable.multiplier(for: symbol, matchCount: matchCount) else { continue }

            let payout = multiplier * bet
            wins.append(SymbolWin(
                symbol: symbol,
                matchCount: matchCount,
                multiplier: multiplier,
                payout: payout,
                cells: contributingCells
            ))
        }

        return wins
    }

    // MARK: - Scatter detection

    /// Count Pearl symbols anywhere on the grid. Award scatter pay if ≥ 3.
    private static func evaluateScatter(grid: [GridCell], bet: Double) -> (count: Int, payout: Double, cells: Set<Int>) {
        let pearlCells = grid.filter { $0.symbol == .pearl }
        let count = pearlCells.count
        let cells = Set(pearlCells.map { $0.id })

        if let multiplier = PayTable.scatterPay(pearlCount: count) {
            return (count, multiplier * bet, cells)
        }
        return (count, 0, [])
    }
}
