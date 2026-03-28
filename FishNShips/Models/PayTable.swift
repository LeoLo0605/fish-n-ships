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
