import SwiftUI

struct SpinButtonView: View {
    let canSpin: Bool
    let onSpin: () -> Void
    let onBetChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button { onBetChange(-1) } label: {
                Image("asset_button_bet_down")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 44)
            }

            Button(action: onSpin) {
                Image("asset_button_spin")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 52)
                    .opacity(canSpin ? 1.0 : 0.5)
            }
            .disabled(!canSpin)

            Button { onBetChange(1) } label: {
                Image("asset_button_bet_up")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 44)
            }
        }
        .padding(.vertical, 12)
    }
}
