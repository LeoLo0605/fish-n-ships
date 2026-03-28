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
