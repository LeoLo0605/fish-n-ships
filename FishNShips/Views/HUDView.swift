import SwiftUI

struct HUDView: View {
    let balance: Double
    let lastWin: Double
    let bet: Double

    var body: some View {
        HStack {
            HUDCell(label: "BAL", value: balance, color: .yellow)
            Spacer()
            HUDCell(label: "WIN", value: lastWin, color: .green)
            Spacer()
            HUDCell(label: "BET", value: bet, color: .yellow)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Color(hex: 0x0D1F3A))
    }
}

private struct HUDCell: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: "USD").precision(.fractionLength(2)))
                .font(.headline.bold())
                .foregroundStyle(color)
        }
    }
}
