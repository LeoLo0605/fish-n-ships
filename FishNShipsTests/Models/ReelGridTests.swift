import XCTest
@testable import FishNShips

final class ReelGridTests: XCTestCase {

    func test_grid_has_15_cells() {
        let grid = ReelGrid()
        XCTAssertEqual(grid.cells.count, 15)
    }

    func test_cell_ids_are_row_major() {
        let grid = ReelGrid()
        for row in 0..<3 {
            for col in 0..<5 {
                let cell = grid.cell(row: row, col: col)
                XCTAssertEqual(cell.id, row * 5 + col)
                XCTAssertEqual(cell.row, row)
                XCTAssertEqual(cell.col, col)
            }
        }
    }

    func test_randomise_changes_symbols() {
        var grid = ReelGrid()
        let original = grid.cells.map { $0.symbol }
        var changed = false
        for _ in 0..<20 {
            grid.randomise()
            if grid.cells.map({ $0.symbol }) != original { changed = true; break }
        }
        XCTAssertTrue(changed)
    }

    func test_randomise_preserves_frame_levels() {
        var grid = ReelGrid()
        grid.cells[0].frameLevel = 3
        grid.randomise()
        XCTAssertEqual(grid.cells[0].frameLevel, 3)
    }

    func test_weighted_random_returns_valid_symbol() {
        for _ in 0..<100 {
            let sym = ReelGrid.weightedRandom()
            XCTAssertTrue(SlotSymbol.allCases.contains(sym))
        }
    }

    func test_weighted_random_distribution_roughly_correct() {
        var counts: [SlotSymbol: Int] = [:]
        for _ in 0..<1000 {
            let sym = ReelGrid.weightedRandom()
            counts[sym, default: 0] += 1
        }
        let pearlCount = counts[.pearl, default: 0]
        let clownfishCount = counts[.clownfish, default: 0]
        XCTAssertLessThan(pearlCount, clownfishCount,
            "Pearl (weight 2) should appear less than clownfish (weight 20)")
    }
}
