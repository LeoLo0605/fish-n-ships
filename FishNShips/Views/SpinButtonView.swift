import SwiftUI

struct SpinButtonView: View {
    let canSpin: Bool
    let onSpin: () -> Void
    let onBetChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button { onBetChange(-1) } label: {
                Text("BET-")
                    .frame(width: 64, height: 44)
                    .background(Color(hex: 0x0D2244))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button(action: onSpin) {
                Text("SPIN")
                    .font(.title3.bold())
                    .frame(width: 120, height: 52)
                    .background(canSpin ? Color(hex: 0xC8860A) : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(!canSpin)

            Button { onBetChange(1) } label: {
                Text("BET+")
                    .frame(width: 64, height: 44)
                    .background(Color(hex: 0x0D2244))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 12)
    }
}
