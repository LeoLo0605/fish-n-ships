import SwiftUI
import SpriteKit

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()

    // GameScene is created once and held for the app's lifetime.
    private let scene: GameScene = {
        let s = GameScene()
        s.scaleMode = .resizeFill
        return s
    }()

    var body: some View {
        ZStack {
            Color(hex: 0x07111F).ignoresSafeArea()

            VStack(spacing: 0) {
                // Title bar
                Text("FISH N' SHIPS")
                    .font(.title2.bold())
                    .foregroundStyle(.yellow)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: 0x0D1F3A))

                // SpriteKit reel grid
                SpriteView(scene: scene)
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .background(Color(hex: 0x040D19))

                // Balance / Win / Bet row
                HUDView(
                    balance: viewModel.balance,
                    lastWin: viewModel.lastWin,
                    bet: viewModel.bet
                )

                // Controls
                SpinButtonView(
                    canSpin: viewModel.canSpin,
                    onSpin: { viewModel.spin() },
                    onBetChange: { viewModel.adjustBet($0) }
                )

                Spacer()
            }
        }
        .onAppear {
            // Wire scene ↔ viewModel here. GameScene.didMove(to:) also attempts wiring,
            // but fires before onAppear so viewModel is not set yet — that path is a no-op.
            // This onAppear call is the guaranteed-safe wiring point. Setting the closure
            // twice on first appearance is harmless.
            scene.viewModel = viewModel
            scene.configure(with: viewModel)
        }
    }
}
