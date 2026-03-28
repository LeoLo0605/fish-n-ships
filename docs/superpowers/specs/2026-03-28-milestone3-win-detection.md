# Fish N' Ships — Milestone 3 Design Spec
**Date:** 2026-03-28
**Scope:** 243-ways win detection, pay table, Wild substitution, Scatter (Pearl) payouts, and winning cell highlight animation.

---

## 1. Overview

Milestone 3 adds the core win system to Fish N' Ships. After each spin, the game evaluates the grid for winning combinations and awards payouts. The system uses **243-ways-to-win** detection (matching symbols on adjacent reels from left to right, any row position) with Wild substitution. Pearl acts as a Scatter with flat payouts. Winning cells receive a highlight animation.

**Tech stack:** unchanged — Swift 5.9, SwiftUI, SpriteKit, iOS 17+.

---

## 2. Win Detection: 243-Ways

For each of the 10 regular symbols (all except Wild and Pearl):

1. For each column left-to-right (col 0 → col 4), check if the symbol **or Wild** appears in any row of that column.
2. If yes, the column is matched — continue to the next column.
3. If no, stop — the consecutive run ends.
4. If run length ≥ 3, record a win.

A single spin can produce multiple wins (e.g., columns 0–2 each contain Clownfish and Octopus in different rows → two separate 3-match wins, both paid).

### Wild behaviour

- Wild substitutes for **any regular symbol** (all except Pearl).
- A column containing Wild matches every regular symbol for the purpose of extending a run.
- Wild has **no standalone payout**. If only Wilds form a consecutive run with no regular symbol present in any matched column, no payout is awarded.
- Wild does **not** substitute for Pearl (scatter).

### Scatter (Pearl) behaviour

- Pearl is evaluated separately from 243-ways detection.
- Count all Pearl cells across the entire 5×3 grid (any position).
- If count ≥ 3, award scatter pay (see pay table below).
- Scatter wins **stack** with 243-ways symbol wins (total payout = sum of all).
- Pearls in consecutive columns do **not** trigger a left-to-right regular win.
- *Note: Free spins trigger reserved for future milestone.*

---

## 3. Pay Table

### Regular symbol payouts (× bet)

| Symbol | Tier | 3-match | 4-match | 5-match |
|---|---|---|---|---|
| Nine | Low | 3× | 10× | 50× |
| Ten | Low | 3× | 10× | 50× |
| Jack | Low | 4× | 15× | 75× |
| Queen | Low | 4× | 15× | 75× |
| King | Low | 5× | 20× | 100× |
| Ace | Low | 5× | 20× | 100× |
| Blue Tang | Med | 8× | 30× | 150× |
| Sea Turtle | Med | 8× | 30× | 150× |
| Octopus | High | 10× | 40× | 200× |
| Clownfish | High | 12× | 50× | 250× |

Wild has no entry — substitution only.

### Scatter payouts (× bet)

| Pearls on grid | Payout |
|---|---|
| 3 | 5× |
| 4 | 20× |
| 5+ | 100× |

---

## 4. Architecture

### New files in `Models/`

**`PayTable.swift`** — Static pay table data.

```swift
struct PayTable {
    /// Returns the bet multiplier for a symbol at a given match count, or nil if no payout.
    static func multiplier(for symbol: SlotSymbol, matchCount: Int) -> Double?

    /// Returns the scatter payout multiplier for a given pearl count, or nil if < 3.
    static func scatterPay(pearlCount: Int) -> Double?
}
```

**`WinResult.swift`** — Output of win evaluation.

```swift
struct SymbolWin {
    let symbol: SlotSymbol
    let matchCount: Int        // 3, 4, or 5
    let multiplier: Double     // from PayTable
    let payout: Double         // multiplier × bet
    let cells: Set<Int>        // cell indices that contributed (for highlighting)
}

struct WinResult {
    let symbolWins: [SymbolWin]
    let scatterCount: Int
    let scatterPayout: Double
    let totalPayout: Double    // sum of all symbolWin payouts + scatterPayout
    var winningCells: Set<Int> // union of all SymbolWin cells + scatter cells
}
```

**`WinEngine.swift`** — Pure evaluation function, no side effects.

```swift
struct WinEngine {
    /// Evaluate the grid for all wins. Returns a WinResult with all payouts and winning cells.
    static func evaluate(grid: [GridCell], bet: Double) -> WinResult
}
```

### Updated: `GameViewModel`

`spinCompleted()` now evaluates wins and updates state:

1. Call `WinEngine.evaluate(grid:bet:)` → `WinResult`
2. Set `lastWin = winResult.totalPayout`
3. Add `winResult.totalPayout` to `balance`
4. Call `onWinHighlight?(winResult.winningCells)` if there's a win
5. Set `isSpinning = false`

New closure property (matches existing `onSpinRequested` pattern):

```swift
var onWinHighlight: ((Set<Int>) -> Void)?
```

### Updated: `GameScene`

- Wires `vm.onWinHighlight` during `configure(with:)`
- New method: `highlightWinningCells(_ cellIndices: Set<Int>)`
  - Winning `SymbolNode`s play a pulse animation (scale 1.0 → 1.15 → 1.0, ~0.3 s)
  - Non-winning cells dim (`alpha = 0.4`) during the highlight, then restore
  - `isSpinning` is set to `false` after the highlight animation completes (not before)

---

## 5. Data Flow (Updated Spin Sequence)

1. User taps SPIN → `viewModel.spin()` → deducts bet, randomises grid, sets `isSpinning = true`, fires `onSpinRequested?()`
2. `GameScene.startSpinAnimation()` runs per-reel animations with staggered stops
3. Last reel finishes → `vm.spinCompleted()`
4. `spinCompleted()` calls `WinEngine.evaluate(grid:bet:)` → `WinResult`
5. Updates `lastWin` and `balance`
6. If `winResult.winningCells` is non-empty → calls `onWinHighlight?(winningCells)`
7. Scene plays highlight animation → on completion, `isSpinning = false`
8. If no win → `isSpinning = false` immediately

---

## 6. Tests

### New: `FishNShipsTests/Models/WinEngineTests.swift`

| Test | Assertion |
|---|---|
| `test_no_win_random_grid` | Grid with no 3+ consecutive matches → empty symbolWins, totalPayout = 0 |
| `test_three_of_a_kind_single_symbol` | Same symbol in any row of cols 0–2 → 3-match win, correct multiplier |
| `test_four_of_a_kind` | Match extends through col 3 → 4-match payout |
| `test_five_of_a_kind` | All 5 columns matched → 5-match payout |
| `test_wild_substitution` | Wild in col 1 extends a run from col 0 through col 2 |
| `test_all_wilds_no_payout` | Columns with only Wilds → no win |
| `test_multiple_wins_same_spin` | Two symbols each match 3+ → both in result, total is sum |
| `test_wild_extends_multiple_symbols` | Wild contributes to wins for two symbols simultaneously |
| `test_winning_cells_correct` | Returned cell indices match exactly the contributing cells |
| `test_scatter_three_pearls` | 3 Pearls anywhere → 5× bet |
| `test_scatter_four_pearls` | 4 Pearls → 20× bet |
| `test_scatter_five_pearls` | 5+ Pearls → 100× bet |
| `test_scatter_two_pearls_no_win` | 2 Pearls → no scatter payout |
| `test_scatter_plus_symbol_wins_stack` | Scatter + symbol wins → total = sum of both |
| `test_pearl_not_counted_as_regular_win` | Pearls in consecutive columns → no left-to-right win |
| `test_wild_does_not_substitute_for_pearl` | Wild doesn't count as Pearl for scatter |

### New: `FishNShipsTests/Models/PayTableTests.swift`

| Test | Assertion |
|---|---|
| `test_all_regular_symbols_have_payouts` | Every non-Wild, non-Pearl symbol has multipliers for 3, 4, 5 |
| `test_wild_has_no_payout` | `PayTable.multiplier(.wild, ...)` returns nil |
| `test_pearl_has_no_regular_payout` | `PayTable.multiplier(.pearl, ...)` returns nil |
| `test_multipliers_increase_with_match_count` | For each symbol, 3× < 4× < 5× |
| `test_match_count_below_3_returns_nil` | matchCount = 2 → nil |

### Updated: `FishNShipsTests/ViewModels/GameViewModelTests.swift`

| Test | Assertion |
|---|---|
| `test_spin_completed_updates_lastWin` | `spinCompleted()` sets `lastWin` to win amount |
| `test_spin_completed_adds_to_balance` | Balance increases by payout after spin |
| `test_spin_completed_no_win_balance_unchanged` | No-win spin doesn't increase balance |

---

## 7. What Milestone 3 Does NOT Include

- Free spins triggered by Pearl scatter (reserved for future milestone)
- Full celebration animation for big wins (reserved — M3 uses pulse highlight only)
- Balance count-up animation
- Win amount floating text on grid
- Per-reel independent strips (all reels share the same global weight distribution)
- RTP tuning / simulation (pay table values are starting points, to be tuned later)
- Pearl light variant animation (`asset_scatter_pearl_light.png` remains unused)
- Sound effects
- Build mechanic / frame levels (field reserved but unused)

---

## 8. Acceptance Criteria

- [ ] `WinEngine.evaluate` correctly detects 243-ways wins for all 10 regular symbols
- [ ] Wild substitutes for regular symbols, does not substitute for Pearl, has no standalone pay
- [ ] Pearl scatter awards 5×/20×/100× bet for 3/4/5+ anywhere on grid
- [ ] Multiple wins on the same spin stack (total = sum of all)
- [ ] `lastWin` and `balance` update correctly after each spin
- [ ] Winning cells pulse-highlight after spin completes; non-winning cells dim
- [ ] `isSpinning` stays true through highlight animation, preventing concurrent spins
- [ ] 24 new unit tests pass (16 WinEngine + 5 PayTable + 3 ViewModel)
- [ ] All existing tests continue to pass
- [ ] No crashes on rapid SPIN taps
