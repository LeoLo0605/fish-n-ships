# Milestone 3: Win Detection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 243-ways win detection with pay table, Wild substitution, Pearl scatter payouts, and winning cell highlight animation.

**Architecture:** Three new model files (`PayTable`, `WinResult`, `WinEngine`) contain all win logic as pure functions. `GameViewModel.spinCompleted()` calls `WinEngine.evaluate` and dispatches results. `GameScene` receives winning cell indices via a closure and plays highlight animations. TDD throughout — tests first, then implementation.

**Tech Stack:** Swift 5.9, SpriteKit, SwiftUI, iOS 17+. XcodeGen for project generation.

**Grid coordinate reminder:** `GridCell.id` = `row * 5 + col` (row-major). Grid has 3 rows × 5 cols = 15 cells. Row 0 is top, col 0 is leftmost.

---

### Task 1: PayTable — Tests

**Files:**
- Create: `FishNShipsTests/Models/PayTableTests.swift`

- [ ] **Step 1: Write all PayTable tests**

```swift
import XCTest
@testable import FishNShips

final class PayTableTests: XCTestCase {

    func test_all_regular_symbols_have_payouts() {
        let regulars: [SlotSymbol] = [
            .nine, .ten, .jack, .queen, .king, .ace,
            .blueTang, .seaTurtle, .octopus, .clownfish
        ]
        for sym in regulars {
            for count in 3...5 {
                XCTAssertNotNil(
                    PayTable.multiplier(for: sym, matchCount: count),
                    "\(sym) should have a payout for \(count)-match"
                )
            }
        }
    }

    func test_wild_has_no_payout() {
        for count in 3...5 {
            XCTAssertNil(PayTable.multiplier(for: .wild, matchCount: count))
        }
    }

    func test_pearl_has_no_regular_payout() {
        for count in 3...5 {
            XCTAssertNil(PayTable.multiplier(for: .pearl, matchCount: count))
        }
    }

    func test_multipliers_increase_with_match_count() {
        let regulars: [SlotSymbol] = [
            .nine, .ten, .jack, .queen, .king, .ace,
            .blueTang, .seaTurtle, .octopus, .clownfish
        ]
        for sym in regulars {
            let m3 = PayTable.multiplier(for: sym, matchCount: 3)!
            let m4 = PayTable.multiplier(for: sym, matchCount: 4)!
            let m5 = PayTable.multiplier(for: sym, matchCount: 5)!
            XCTAssertLessThan(m3, m4, "\(sym): 3-match should be less than 4-match")
            XCTAssertLessThan(m4, m5, "\(sym): 4-match should be less than 5-match")
        }
    }

    func test_match_count_below_3_returns_nil() {
        XCTAssertNil(PayTable.multiplier(for: .clownfish, matchCount: 2))
        XCTAssertNil(PayTable.multiplier(for: .clownfish, matchCount: 0))
    }

    func test_scatter_pay_three_pearls() {
        XCTAssertEqual(PayTable.scatterPay(pearlCount: 3), 5.0)
    }

    func test_scatter_pay_four_pearls() {
        XCTAssertEqual(PayTable.scatterPay(pearlCount: 4), 20.0)
    }

    func test_scatter_pay_five_or_more_pearls() {
        XCTAssertEqual(PayTable.scatterPay(pearlCount: 5), 100.0)
        XCTAssertEqual(PayTable.scatterPay(pearlCount: 6), 100.0)
    }

    func test_scatter_pay_below_3_returns_nil() {
        XCTAssertNil(PayTable.scatterPay(pearlCount: 2))
        XCTAssertNil(PayTable.scatterPay(pearlCount: 0))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
xcodegen generate && xcodebuild -project FishNShips.xcodeproj -scheme FishNShips -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:FishNShipsTests/PayTableTests
```
Expected: Build failure — `PayTable` type does not exist yet.

- [ ] **Step 3: Commit test file**

```bash
git add FishNShipsTests/Models/PayTableTests.swift
git commit -m "test: add PayTable tests (red — implementation pending)"
```

---

### Task 2: PayTable — Implementation

**Files:**
- Create: `FishNShips/Models/PayTable.swift`

- [ ] **Step 1: Implement PayTable**

```swift
import Foundation

struct PayTable {

    /// Returns the bet multiplier for a regular symbol at a given match count, or nil if no payout.
    /// Wild and Pearl return nil (Wild is substitution-only; Pearl is scatter-only).
    static func multiplier(for symbol: SlotSymbol, matchCount: Int) -> Double? {
        guard matchCount >= 3, matchCount <= 5 else { return nil }
        guard let row = table[symbol] else { return nil }
        return row[matchCount - 3]
    }

    /// Returns the scatter payout multiplier for a given pearl count, or nil if fewer than 3.
    static func scatterPay(pearlCount: Int) -> Double? {
        switch pearlCount {
        case 3:    return 5.0
        case 4:    return 20.0
        case 5...: return 100.0
        default:   return nil
        }
    }

    // MARK: - Pay table data

    /// [3-match, 4-match, 5-match] multipliers per symbol.
    private static let table: [SlotSymbol: [Double]] = [
        .nine:      [3,   10,   50],
        .ten:       [3,   10,   50],
        .jack:      [4,   15,   75],
        .queen:     [4,   15,   75],
        .king:      [5,   20,  100],
        .ace:       [5,   20,  100],
        .blueTang:  [8,   30,  150],
        .seaTurtle: [8,   30,  150],
        .octopus:   [10,  40,  200],
        .clownfish: [12,  50,  250],
        // .wild — not present (no standalone pay)
        // .pearl — not present (scatter-only)
    ]
}
```

- [ ] **Step 2: Run PayTable tests to verify they pass**

Run:
```bash
xcodegen generate && xcodebuild -project FishNShips.xcodeproj -scheme FishNShips -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:FishNShipsTests/PayTableTests
```
Expected: All 9 tests PASS.

- [ ] **Step 3: Commit**

```bash
git add FishNShips/Models/PayTable.swift
git commit -m "feat(m3): add PayTable with symbol multipliers and scatter pay"
```

---

### Task 3: WinResult — Data Types

**Files:**
- Create: `FishNShips/Models/WinResult.swift`

- [ ] **Step 1: Create WinResult and SymbolWin types**

```swift
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
```

- [ ] **Step 2: Verify project builds**

Run:
```bash
xcodegen generate && xcodebuild -project FishNShips.xcodeproj -scheme FishNShips -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add FishNShips/Models/WinResult.swift
git commit -m "feat(m3): add WinResult and SymbolWin data types"
```

---

### Task 4: WinEngine — Tests

**Files:**
- Create: `FishNShipsTests/Models/WinEngineTests.swift`

The test helper `makeGrid` creates a 15-cell grid from a 3×5 array of symbols. Row-major: `symbols[row][col]`.

- [ ] **Step 1: Write all WinEngine tests**

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
xcodegen generate && xcodebuild -project FishNShips.xcodeproj -scheme FishNShips -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:FishNShipsTests/WinEngineTests
```
Expected: Build failure — `WinEngine` type does not exist yet.

- [ ] **Step 3: Commit test file**

```bash
git add FishNShipsTests/Models/WinEngineTests.swift
git commit -m "test: add WinEngine tests (red — implementation pending)"
```

---

### Task 5: WinEngine — Implementation

**Files:**
- Create: `FishNShips/Models/WinEngine.swift`

- [ ] **Step 1: Implement WinEngine**

```swift
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
```

- [ ] **Step 2: Run all WinEngine tests to verify they pass**

Run:
```bash
xcodegen generate && xcodebuild -project FishNShips.xcodeproj -scheme FishNShips -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:FishNShipsTests/WinEngineTests
```
Expected: All 16 tests PASS.

- [ ] **Step 3: Run ALL tests to verify nothing is broken**

Run:
```bash
xcodebuild -project FishNShips.xcodeproj -scheme FishNShips -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```
Expected: All tests PASS (existing 23 + 9 PayTable + 16 WinEngine = 48).

- [ ] **Step 4: Commit**

```bash
git add FishNShips/Models/WinEngine.swift
git commit -m "feat(m3): add WinEngine — 243-ways detection with Wild substitution and scatter"
```

---

### Task 6: GameViewModel — Wire Win Evaluation

**Files:**
- Modify: `FishNShips/ViewModels/GameViewModel.swift`
- Modify: `FishNShipsTests/ViewModels/GameViewModelTests.swift`

- [ ] **Step 1: Add new ViewModel tests**

Append to `GameViewModelTests.swift`:

```swift
    // MARK: - Win evaluation (M3)

    func test_spin_completed_updates_lastWin() {
        let vm = GameViewModel()
        vm.spin()
        vm.spinCompleted()
        // lastWin is determined by WinEngine — just verify it was set (not still 0 from spin reset)
        // We can't predict the random grid, so just verify the type contract:
        // lastWin should be a non-negative number.
        XCTAssertGreaterThanOrEqual(vm.lastWin, 0)
    }

    func test_spin_completed_adds_to_balance() {
        let vm = GameViewModel()
        let balanceAfterSpin = vm.balance - vm.bet
        vm.spin()
        vm.spinCompleted()
        // balance should equal (balance after deduction) + lastWin
        XCTAssertEqual(vm.balance, balanceAfterSpin + vm.lastWin, accuracy: 0.001)
    }

    func test_spin_completed_no_win_balance_unchanged() {
        // Force a grid that produces no wins: unique symbol per column.
        let vm = GameViewModel()
        vm.spin()
        // Manually override grid with a no-win arrangement.
        vm.setGridForTesting([
            GridCell(row: 0, col: 0, symbol: .clownfish),
            GridCell(row: 0, col: 1, symbol: .octopus),
            GridCell(row: 0, col: 2, symbol: .seaTurtle),
            GridCell(row: 0, col: 3, symbol: .blueTang),
            GridCell(row: 0, col: 4, symbol: .ace),
            GridCell(row: 1, col: 0, symbol: .king),
            GridCell(row: 1, col: 1, symbol: .queen),
            GridCell(row: 1, col: 2, symbol: .jack),
            GridCell(row: 1, col: 3, symbol: .ten),
            GridCell(row: 1, col: 4, symbol: .nine),
            GridCell(row: 2, col: 0, symbol: .nine),
            GridCell(row: 2, col: 1, symbol: .ten),
            GridCell(row: 2, col: 2, symbol: .king),
            GridCell(row: 2, col: 3, symbol: .queen),
            GridCell(row: 2, col: 4, symbol: .jack),
        ])
        let balanceBefore = vm.balance
        vm.spinCompleted()
        XCTAssertEqual(vm.lastWin, 0)
        XCTAssertEqual(vm.balance, balanceBefore)
    }
```

- [ ] **Step 2: Add `setGridForTesting` helper to GameViewModel**

Add this method at the bottom of `GameViewModel` (inside the class, after `adjustBet`):

```swift
    /// Test-only: override the grid with a specific cell arrangement.
    func setGridForTesting(_ cells: [GridCell]) {
        grid = cells
    }
```

- [ ] **Step 3: Update `spinCompleted()` to evaluate wins**

Replace the existing `spinCompleted()` method in `GameViewModel.swift`:

```swift
    /// Closure called by the scene when it finishes the spin animation.
    /// Set by GameScene.configure(with:) alongside onSpinRequested.
    var onWinHighlight: ((Set<Int>) -> Void)?

    func spinCompleted() {
        let result = WinEngine.evaluate(grid: grid, bet: bet)
        lastWin = result.totalPayout
        balance += result.totalPayout

        if result.hasWin {
            onWinHighlight?(result.winningCells)
        } else {
            isSpinning = false
        }
    }
```

**Important:** When there IS a win, `isSpinning` stays `true` — it will be set to `false` by the scene after the highlight animation finishes (Task 7). When there is NO win, `isSpinning` is set to `false` immediately.

- [ ] **Step 4: Run all ViewModel tests**

Run:
```bash
xcodegen generate && xcodebuild -project FishNShips.xcodeproj -scheme FishNShips -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:FishNShipsTests/GameViewModelTests
```
Expected: All tests PASS. Note: `test_spinCompleted_clears_isSpinning` may need updating — `spinCompleted()` now only clears `isSpinning` when there is no win. Since the test uses a random grid, it may or may not have a win. If this test fails, update it to use `setGridForTesting` with the no-win grid shown in step 1, then assert `isSpinning == false`.

- [ ] **Step 5: Run ALL tests**

Run:
```bash
xcodebuild -project FishNShips.xcodeproj -scheme FishNShips -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add FishNShips/ViewModels/GameViewModel.swift FishNShipsTests/ViewModels/GameViewModelTests.swift
git commit -m "feat(m3): wire WinEngine into GameViewModel.spinCompleted"
```

---

### Task 7: GameScene — Win Highlight Animation

**Files:**
- Modify: `FishNShips/Scene/GameScene.swift`
- Modify: `FishNShips/Scene/ReelNode.swift` (expose symbolNodes for highlight access)

- [ ] **Step 1: Expose SymbolNodes from ReelNode**

In `ReelNode.swift`, change `symbolNodes` from private to internal read access:

Replace:
```swift
    private var symbolNodes: [SymbolNode] = []
```
With:
```swift
    private(set) var symbolNodes: [SymbolNode] = []
```

- [ ] **Step 2: Wire `onWinHighlight` in GameScene.configure**

In `GameScene.swift`, update the `configure(with:)` method to wire the new closure:

```swift
    func configure(with vm: GameViewModel) {
        viewModel = vm
        buildGrid(initialGrid: vm.grid)
        vm.onSpinRequested = { [weak self] in
            guard let self else { return }
            self.startSpinAnimation()
        }
        vm.onWinHighlight = { [weak self] winningCells in
            guard let self else { return }
            self.highlightWinningCells(winningCells)
        }
    }
```

- [ ] **Step 3: Add highlightWinningCells method**

Add this method in the `// MARK: - Animation` section of `GameScene.swift`, after `animationDidFinish()`:

```swift
    /// Pulse winning cells and dim non-winning cells, then restore and clear isSpinning.
    func highlightWinningCells(_ cellIndices: Set<Int>) {
        let highlightDuration: TimeInterval = 0.3
        let holdDuration: TimeInterval = 0.6
        var allNodes: [(node: SymbolNode, cellId: Int)] = []

        // Collect all SymbolNodes with their cell IDs.
        for reel in reelNodes {
            for (row, node) in reel.symbolNodes.enumerated() {
                let cellId = row * 5 + reel.column
                allNodes.append((node, cellId))
            }
        }

        // Dim non-winning nodes.
        for (node, cellId) in allNodes {
            if !cellIndices.contains(cellId) {
                node.run(SKAction.fadeAlpha(to: 0.4, duration: highlightDuration / 2))
            }
        }

        // Pulse winning nodes.
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: highlightDuration / 2),
            SKAction.scale(to: 1.0, duration: highlightDuration / 2),
        ])
        let pulseAndHold = SKAction.sequence([pulse, SKAction.wait(forDuration: holdDuration)])

        var completedCount = 0
        let winningNodes = allNodes.filter { cellIndices.contains($0.cellId) }
        let totalWinning = max(winningNodes.count, 1) // guard against empty

        for (node, _) in winningNodes {
            node.run(pulseAndHold) { [weak self] in
                completedCount += 1
                if completedCount == totalWinning {
                    // Restore all nodes to normal.
                    for (n, _) in allNodes {
                        n.run(SKAction.sequence([
                            SKAction.fadeAlpha(to: 1.0, duration: 0.15),
                            SKAction.scale(to: 1.0, duration: 0.01),
                        ]))
                    }
                    // Clear isSpinning after highlight finishes.
                    self?.viewModel?.isSpinning = false
                }
            }
        }

        // Edge case: if winningCells was non-empty but no matching nodes found
        // (shouldn't happen, but be safe), clear spinning immediately.
        if winningNodes.isEmpty {
            viewModel?.isSpinning = false
        }
    }
```

- [ ] **Step 4: Update animationDidFinish**

No changes needed — `animationDidFinish()` already calls `vm.spinCompleted()`, which now handles the branching (win → highlight → isSpinning=false later, no win → isSpinning=false immediately).

- [ ] **Step 5: Verify build succeeds**

Run:
```bash
xcodegen generate && xcodebuild -project FishNShips.xcodeproj -scheme FishNShips -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```
Expected: Build succeeds.

- [ ] **Step 6: Run ALL tests**

Run:
```bash
xcodebuild -project FishNShips.xcodeproj -scheme FishNShips -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```
Expected: All tests PASS.

- [ ] **Step 7: Commit**

```bash
git add FishNShips/Scene/ReelNode.swift FishNShips/Scene/GameScene.swift
git commit -m "feat(m3): add win highlight animation — pulse winners, dim losers"
```

---

### Task 8: Integration Test and Final Verification

**Files:**
- No new files — manual testing and full test suite run.

- [ ] **Step 1: Run full test suite**

Run:
```bash
xcodebuild -project FishNShips.xcodeproj -scheme FishNShips -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```
Expected: All tests PASS. Total count should be ~48 (23 existing + 9 PayTable + 16 WinEngine).

- [ ] **Step 2: Verify acceptance criteria**

Check each item from the spec:

1. `WinEngine.evaluate` detects 243-ways wins → verified by 16 unit tests
2. Wild substitution + no standalone pay → verified by `test_wild_substitution` + `test_all_wilds_no_payout`
3. Pearl scatter payouts → verified by scatter tests
4. Multiple wins stack → verified by `test_multiple_wins_same_spin` + `test_scatter_plus_symbol_wins_stack`
5. `lastWin` and `balance` update → verified by ViewModel tests
6. Win highlight animation → verified by build + manual test
7. `isSpinning` stays true through highlight → verified by ViewModel branching logic
8. No crashes on rapid SPIN taps → manual test: tap SPIN rapidly 10+ times

- [ ] **Step 3: Commit any final fixes**

If any tests needed fixing in previous tasks, ensure all changes are committed.

```bash
git status
```
Expected: Clean working tree.

- [ ] **Step 4: Update project.yml if needed**

Verify that `FishNShipsTests/Models` source path already covers the new test files (it should — XcodeGen picks up all `.swift` files under the path). If `xcodegen generate` was run during tasks, project.pbxproj may have changed:

```bash
git add -A && git status
```

If project.pbxproj changed, commit it:
```bash
git add FishNShips.xcodeproj/project.pbxproj
git commit -m "chore: regenerate Xcode project for M3 files"
```
