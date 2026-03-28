import XCTest
@testable import FishNShips

final class WinEngineTests: XCTestCase {

    // MARK: - Test helper

    /// Build a [GridCell] from a 3×5 symbol array (row-major).
    private func makeGrid(_ symbols: [[SlotSymbol]]) -> [GridCell] {
        var cells: [GridCell] = []
        for row in 0..<3 {
            for col in 0..<5 {
                cells.append(GridCell(row: row, col: col, symbol: symbols[row][col]))
            }
        }
        return cells
    }

    // MARK: - 243-ways symbol wins

    func test_no_win_random_grid() {
        // Each column has a unique symbol — no 3-consecutive match possible
        let grid = makeGrid([
            [.clownfish, .octopus,   .seaTurtle, .blueTang,  .ace],
            [.king,      .queen,     .jack,      .ten,       .nine],
            [.pearl,     .pearl,     .wild,      .clownfish, .octopus],
        ])
        let result = WinEngine.evaluate(grid: grid, bet: 1.0)
        XCTAssertTrue(result.symbolWins.isEmpty)
        XCTAssertEqual(result.totalPayout, 0)
    }

    func test_three_of_a_kind_single_symbol() {
        // Clownfish in row 0 of cols 0-2, different symbols in cols 3-4
        let grid = makeGrid([
            [.clownfish, .clownfish, .clownfish, .octopus, .ace],
            [.nine,      .ten,       .jack,      .queen,   .king],
            [.ace,       .king,      .queen,     .jack,    .ten],
        ])
        let result = WinEngine.evaluate(grid: grid, bet: 2.0)
        XCTAssertEqual(result.symbolWins.count, 1)
        let win = result.symbolWins[0]
        XCTAssertEqual(win.symbol, .clownfish)
        XCTAssertEqual(win.matchCount, 3)
        XCTAssertEqual(win.multiplier, 12.0)
        XCTAssertEqual(win.payout, 24.0) // 12 × 2.0
        XCTAssertEqual(result.totalPayout, 24.0)
    }

    func test_four_of_a_kind() {
        let grid = makeGrid([
            [.octopus, .octopus, .octopus, .octopus, .ace],
            [.nine,    .ten,     .jack,    .queen,   .king],
            [.ace,     .king,    .queen,   .jack,    .ten],
        ])
        let result = WinEngine.evaluate(grid: grid, bet: 1.0)
        XCTAssertEqual(result.symbolWins.count, 1)
        let win = result.symbolWins[0]
        XCTAssertEqual(win.symbol, .octopus)
        XCTAssertEqual(win.matchCount, 4)
        XCTAssertEqual(win.multiplier, 40.0)
        XCTAssertEqual(win.payout, 40.0)
    }

    func test_five_of_a_kind() {
        let grid = makeGrid([
            [.nine, .nine, .nine, .nine, .nine],
            [.ace,  .king, .queen, .jack, .ten],
            [.ace,  .king, .queen, .jack, .ten],
        ])
        let result = WinEngine.evaluate(grid: grid, bet: 1.0)
        XCTAssertEqual(result.symbolWins.count, 1)
        let win = result.symbolWins[0]
        XCTAssertEqual(win.symbol, .nine)
        XCTAssertEqual(win.matchCount, 5)
        XCTAssertEqual(win.multiplier, 50.0)
    }

    func test_wild_substitution() {
        // Clownfish col0, Wild col1, Clownfish col2 → 3-of-a-kind clownfish
        let grid = makeGrid([
            [.clownfish, .wild,  .clownfish, .octopus, .ace],
            [.nine,      .ten,   .jack,      .queen,   .king],
            [.ace,       .king,  .queen,     .jack,    .ten],
        ])
        let result = WinEngine.evaluate(grid: grid, bet: 1.0)
        let clownfishWins = result.symbolWins.filter { $0.symbol == .clownfish }
        XCTAssertEqual(clownfishWins.count, 1)
        XCTAssertEqual(clownfishWins[0].matchCount, 3)
    }

    func test_all_wilds_no_payout() {
        // 3 columns of only Wilds — no regular symbol → no win
        let grid = makeGrid([
            [.wild, .wild, .wild, .octopus, .ace],
            [.wild, .wild, .wild, .queen,   .king],
            [.wild, .wild, .wild, .jack,    .ten],
        ])
        let result = WinEngine.evaluate(grid: grid, bet: 1.0)
        XCTAssertTrue(result.symbolWins.isEmpty)
    }

    func test_multiple_wins_same_spin() {
        // Row 0: clownfish across cols 0-2, Row 1: octopus across cols 0-2
        let grid = makeGrid([
            [.clownfish, .clownfish, .clownfish, .nine, .ten],
            [.octopus,   .octopus,   .octopus,   .nine, .ten],
            [.ace,       .king,      .queen,     .jack, .ten],
        ])
        let result = WinEngine.evaluate(grid: grid, bet: 1.0)
        let symbols = Set(result.symbolWins.map { $0.symbol })
        XCTAssertTrue(symbols.contains(.clownfish))
        XCTAssertTrue(symbols.contains(.octopus))
        XCTAssertEqual(result.totalPayout, 12.0 + 10.0) // clownfish 3×=12, octopus 3×=10
    }

    func test_wild_extends_multiple_symbols() {
        // Col 0 has clownfish+octopus, col 1 all wilds, col 2 has clownfish+octopus
        let grid = makeGrid([
            [.clownfish, .wild, .clownfish, .nine, .ten],
            [.octopus,   .wild, .octopus,   .nine, .ten],
            [.ace,       .wild, .queen,     .jack, .ten],
        ])
        let result = WinEngine.evaluate(grid: grid, bet: 1.0)
        let symbols = Set(result.symbolWins.map { $0.symbol })
        XCTAssertTrue(symbols.contains(.clownfish))
        XCTAssertTrue(symbols.contains(.octopus))
    }

    func test_winning_cells_correct() {
        // Clownfish across cols 0-2 in rows 0 and 1, plus wild in col 1 row 2
        let grid = makeGrid([
            [.clownfish, .clownfish, .clownfish, .nine, .ten],
            [.clownfish, .wild,      .clownfish, .nine, .ten],
            [.ace,       .wild,      .queen,     .jack, .ten],
        ])
        let result = WinEngine.evaluate(grid: grid, bet: 1.0)
        let clownfishWin = result.symbolWins.first { $0.symbol == .clownfish }!
        // Col 0: rows 0,1 have clownfish → ids 0, 5
        // Col 1: row 0 has clownfish, rows 1,2 have wild → ids 1, 6, 11
        // Col 2: rows 0,1 have clownfish → ids 2, 7
        let expected: Set<Int> = [0, 5, 1, 6, 11, 2, 7]
        XCTAssertEqual(clownfishWin.cells, expected)
    }

    // MARK: - Scatter (Pearl)

    func test_scatter_three_pearls() {
        let grid = makeGrid([
            [.pearl,     .nine, .pearl, .ace,   .ten],
            [.clownfish, .ten,  .jack,  .queen, .king],
            [.ace,       .king, .pearl, .jack,  .ten],
        ])
        let result = WinEngine.evaluate(grid: grid, bet: 2.0)
        XCTAssertEqual(result.scatterCount, 3)
        XCTAssertEqual(result.scatterPayout, 10.0) // 5 × 2.0
    }

    func test_scatter_four_pearls() {
        let grid = makeGrid([
            [.pearl,     .pearl, .nine,  .ace,   .pearl],
            [.clownfish, .ten,   .jack,  .queen, .king],
            [.ace,       .king,  .pearl, .jack,  .ten],
        ])
        let result = WinEngine.evaluate(grid: grid, bet: 1.0)
        XCTAssertEqual(result.scatterCount, 4)
        XCTAssertEqual(result.scatterPayout, 20.0) // 20 × 1.0
    }

    func test_scatter_five_pearls() {
        let grid = makeGrid([
            [.pearl, .pearl, .pearl, .ace,   .ten],
            [.nine,  .ten,   .jack,  .queen, .king],
            [.ace,   .pearl, .pearl, .jack,  .ten],
        ])
        let result = WinEngine.evaluate(grid: grid, bet: 1.0)
        XCTAssertEqual(result.scatterCount, 5)
        XCTAssertEqual(result.scatterPayout, 100.0)
    }

    func test_scatter_two_pearls_no_win() {
        let grid = makeGrid([
            [.pearl,     .nine, .pearl, .ace,   .ten],
            [.clownfish, .ten,  .jack,  .queen, .king],
            [.ace,       .king, .queen, .jack,  .ten],
        ])
        let result = WinEngine.evaluate(grid: grid, bet: 1.0)
        XCTAssertEqual(result.scatterCount, 2)
        XCTAssertEqual(result.scatterPayout, 0)
    }

    func test_scatter_plus_symbol_wins_stack() {
        // 3 pearls (scatter) + clownfish 3-of-a-kind (symbol win)
        let grid = makeGrid([
            [.clownfish, .clownfish, .clownfish, .pearl, .pearl],
            [.nine,      .ten,       .jack,      .queen, .king],
            [.pearl,     .king,      .queen,     .jack,  .ten],
        ])
        let result = WinEngine.evaluate(grid: grid, bet: 1.0)
        XCTAssertEqual(result.scatterPayout, 5.0)  // 3 pearls × 5 × bet
        let symbolPay = result.symbolWins.reduce(0.0) { $0 + $1.payout }
        XCTAssertEqual(symbolPay, 12.0) // clownfish 3-match
        XCTAssertEqual(result.totalPayout, 17.0) // 5 + 12
    }

    func test_pearl_not_counted_as_regular_win() {
        // Pearls in cols 0-2 but pearl has no regular pay table entry
        let grid = makeGrid([
            [.pearl, .pearl, .pearl, .ace,   .ten],
            [.nine,  .ten,   .jack,  .queen, .king],
            [.ace,   .king,  .queen, .jack,  .ten],
        ])
        let result = WinEngine.evaluate(grid: grid, bet: 1.0)
        // Should have scatter pay but NO symbol win for pearl
        let pearlSymbolWins = result.symbolWins.filter { $0.symbol == .pearl }
        XCTAssertTrue(pearlSymbolWins.isEmpty)
    }

    func test_wild_does_not_substitute_for_pearl() {
        // 2 pearls + 1 wild should NOT count as 3 pearls for scatter
        let grid = makeGrid([
            [.pearl, .wild,  .pearl, .ace,   .ten],
            [.nine,  .ten,   .jack,  .queen, .king],
            [.ace,   .king,  .queen, .jack,  .ten],
        ])
        let result = WinEngine.evaluate(grid: grid, bet: 1.0)
        XCTAssertEqual(result.scatterCount, 2)
        XCTAssertEqual(result.scatterPayout, 0)
    }
}
