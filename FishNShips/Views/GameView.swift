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
                Image("asset_game_title")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 60)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: 0x0D1F3A))

                // SpriteKit reel grid — expands to fill available space
                SpriteView(scene: scene)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .padding(.bottom, 16)
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
