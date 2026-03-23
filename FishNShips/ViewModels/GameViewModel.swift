import Foundation

@MainActor
final class GameViewModel: ObservableObject {
    @Published var balance: Double = 1000.0
    @Published var bet: Double = 1.0
    @Published var lastWin: Double = 0.0
    @Published var grid: [GridCell]
    @Published var isSpinning: Bool = false

    var canSpin: Bool { !isSpinning && balance >= bet }

    /// Set by GameScene.configure(with:) in didMove(to:)
    var onSpinRequested: (() -> Void)?

    private let betSteps: [Double] = [0.50, 1.00, 2.00, 5.00, 10.00, 20.00, 50.00]
    private var reelGrid = ReelGrid()

    init() {
        grid = reelGrid.cells
    }

    func spin() {
        guard canSpin else { return }
        balance -= bet
        lastWin = 0.0
        reelGrid.randomise()
        grid = reelGrid.cells
        isSpinning = true
        onSpinRequested?()
    }

    func spinCompleted() {
        isSpinning = false
    }

    func adjustBet(_ delta: Int) {
        guard let currentIndex = betSteps.firstIndex(of: bet) else { return }
        let newIndex = max(0, min(betSteps.count - 1, currentIndex + delta))
        bet = betSteps[newIndex]
    }
}
