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
}
