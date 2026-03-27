import XCTest
@testable import FishNShips

final class SlotSymbolTests: XCTestCase {

    func test_case_count_is_12() {
        XCTAssertEqual(SlotSymbol.allCases.count, 12)
    }

    func test_weights_sum_to_100() {
        let total = SlotSymbol.allCases.reduce(0) { $0 + $1.weight }
        XCTAssertEqual(total, 100)
    }

    func test_all_cases_have_image_name() {
        for symbol in SlotSymbol.allCases {
            XCTAssertFalse(symbol.imageName.isEmpty, "\(symbol) has empty imageName")
        }
    }
}
