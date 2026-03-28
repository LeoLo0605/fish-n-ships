import XCTest
@testable import FishNShips

@MainActor
final class GameViewModelTests: XCTestCase {

    func test_initial_state() {
        let vm = GameViewModel()
        XCTAssertEqual(vm.balance, 1000.0)
        XCTAssertEqual(vm.bet, 1.0)
        XCTAssertEqual(vm.lastWin, 0.0)
        XCTAssertFalse(vm.isSpinning)
        XCTAssertEqual(vm.grid.count, 15)
    }

    func test_spin_deducts_bet() {
        let vm = GameViewModel()
        vm.spin()
        XCTAssertEqual(vm.balance, 999.0)
    }

    func test_spin_sets_isSpinning_true() {
        let vm = GameViewModel()
        vm.spin()
        XCTAssertTrue(vm.isSpinning)
    }

    func test_spin_resets_lastWin() {
        let vm = GameViewModel()
        vm.lastWin = 50.0
        vm.spin()
        XCTAssertEqual(vm.lastWin, 0.0)
    }

    func test_spinCompleted_clears_isSpinning() {
        let vm = GameViewModel()
        vm.spin()
        // Force a no-win grid so isSpinning clears immediately (no highlight delay).
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
        vm.spinCompleted()
        XCTAssertFalse(vm.isSpinning)
    }

    func test_spin_noop_when_already_spinning() {
        let vm = GameViewModel()
        vm.spin()
        let balanceAfterFirst = vm.balance
        vm.spin()  // should be ignored
        XCTAssertEqual(vm.balance, balanceAfterFirst)
    }

    func test_spin_noop_when_balance_less_than_bet() {
        let vm = GameViewModel()
        vm.balance = 0.40
        vm.bet = 0.50
        vm.spin()
        XCTAssertFalse(vm.isSpinning)
        XCTAssertEqual(vm.balance, 0.40)
    }

    func test_canSpin_false_when_spinning() {
        let vm = GameViewModel()
        vm.spin()
        XCTAssertFalse(vm.canSpin)
    }

    func test_canSpin_false_when_balance_below_bet() {
        let vm = GameViewModel()
        vm.balance = 0.0
        XCTAssertFalse(vm.canSpin)
    }

    func test_adjustBet_increases() {
        let vm = GameViewModel()
        vm.bet = 1.0
        vm.adjustBet(1)
        XCTAssertEqual(vm.bet, 2.0)
    }

    func test_adjustBet_decreases() {
        let vm = GameViewModel()
        vm.bet = 1.0
        vm.adjustBet(-1)
        XCTAssertEqual(vm.bet, 0.50)
    }

    func test_adjustBet_clamps_at_max() {
        let vm = GameViewModel()
        vm.bet = 50.0
        vm.adjustBet(1)
        XCTAssertEqual(vm.bet, 50.0)
    }

    func test_adjustBet_clamps_at_min() {
        let vm = GameViewModel()
        vm.bet = 0.50
        vm.adjustBet(-1)
        XCTAssertEqual(vm.bet, 0.50)
    }

    func test_spin_fires_onSpinRequested() {
        let vm = GameViewModel()
        var fired = false
        vm.onSpinRequested = { fired = true }
        vm.spin()
        XCTAssertTrue(fired)
    }

    // MARK: - Win evaluation (M3)

    func test_spin_completed_updates_lastWin() {
        let vm = GameViewModel()
        vm.spin()
        // Inject a 5-of-a-kind Clownfish grid: row 0 all clownfish, rows 1-2 mixed non-clownfish/non-wild.
        vm.setGridForTesting([
            GridCell(row: 0, col: 0, symbol: .clownfish),
            GridCell(row: 0, col: 1, symbol: .clownfish),
            GridCell(row: 0, col: 2, symbol: .clownfish),
            GridCell(row: 0, col: 3, symbol: .clownfish),
            GridCell(row: 0, col: 4, symbol: .clownfish),
            GridCell(row: 1, col: 0, symbol: .nine),
            GridCell(row: 1, col: 1, symbol: .ten),
            GridCell(row: 1, col: 2, symbol: .jack),
            GridCell(row: 1, col: 3, symbol: .queen),
            GridCell(row: 1, col: 4, symbol: .king),
            GridCell(row: 2, col: 0, symbol: .ten),
            GridCell(row: 2, col: 1, symbol: .jack),
            GridCell(row: 2, col: 2, symbol: .queen),
            GridCell(row: 2, col: 3, symbol: .king),
            GridCell(row: 2, col: 4, symbol: .ace),
        ])
        vm.spinCompleted()
        // 5-of-a-kind Clownfish with bet=1.0 pays 250×1.0 = 250.0
        XCTAssertEqual(vm.lastWin, 250.0)
        XCTAssertTrue(vm.isSpinning, "isSpinning should remain true until winHighlightCompleted() is called")
    }

    func test_spin_completed_adds_to_balance() {
        let vm = GameViewModel()
        vm.spin()
        // spin() deducts bet: balance = 1000.0 - 1.0 = 999.0
        // Inject a 5-of-a-kind Clownfish grid: pays 250×1.0 = 250.0
        vm.setGridForTesting([
            GridCell(row: 0, col: 0, symbol: .clownfish),
            GridCell(row: 0, col: 1, symbol: .clownfish),
            GridCell(row: 0, col: 2, symbol: .clownfish),
            GridCell(row: 0, col: 3, symbol: .clownfish),
            GridCell(row: 0, col: 4, symbol: .clownfish),
            GridCell(row: 1, col: 0, symbol: .nine),
            GridCell(row: 1, col: 1, symbol: .ten),
            GridCell(row: 1, col: 2, symbol: .jack),
            GridCell(row: 1, col: 3, symbol: .queen),
            GridCell(row: 1, col: 4, symbol: .king),
            GridCell(row: 2, col: 0, symbol: .ten),
            GridCell(row: 2, col: 1, symbol: .jack),
            GridCell(row: 2, col: 2, symbol: .queen),
            GridCell(row: 2, col: 3, symbol: .king),
            GridCell(row: 2, col: 4, symbol: .ace),
        ])
        vm.spinCompleted()
        // balance = 999.0 + 250.0 = 1249.0
        XCTAssertEqual(vm.balance, 1249.0, accuracy: 0.001)
        XCTAssertTrue(vm.isSpinning, "isSpinning should remain true until winHighlightCompleted() is called")
    }

    func test_winHighlightCompleted_clears_isSpinning() {
        let vm = GameViewModel()
        vm.spin()
        // Inject a 5-of-a-kind Clownfish grid so spinCompleted() holds isSpinning.
        vm.setGridForTesting([
            GridCell(row: 0, col: 0, symbol: .clownfish),
            GridCell(row: 0, col: 1, symbol: .clownfish),
            GridCell(row: 0, col: 2, symbol: .clownfish),
            GridCell(row: 0, col: 3, symbol: .clownfish),
            GridCell(row: 0, col: 4, symbol: .clownfish),
            GridCell(row: 1, col: 0, symbol: .nine),
            GridCell(row: 1, col: 1, symbol: .ten),
            GridCell(row: 1, col: 2, symbol: .jack),
            GridCell(row: 1, col: 3, symbol: .queen),
            GridCell(row: 1, col: 4, symbol: .king),
            GridCell(row: 2, col: 0, symbol: .ten),
            GridCell(row: 2, col: 1, symbol: .jack),
            GridCell(row: 2, col: 2, symbol: .queen),
            GridCell(row: 2, col: 3, symbol: .king),
            GridCell(row: 2, col: 4, symbol: .ace),
        ])
        vm.spinCompleted()
        XCTAssertTrue(vm.isSpinning)       // spin lock held

        vm.winHighlightCompleted()
        XCTAssertFalse(vm.isSpinning)      // now released
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
}
