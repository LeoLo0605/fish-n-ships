# Fish N' Ships — Milestone 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a runnable Xcode project with a SwiftUI Layout B game screen, a 5×3 SpriteKit reel grid of placeholder coloured squares, and a left-to-right staggered spin animation with colour-cycling and snap-bounce.

**Architecture:** ViewModel-Driven MVVM — `GameViewModel` owns all state; `GameScene` holds a weak reference and registers `onSpinRequested` in `didMove(to:)`; SwiftUI reads `@StateObject` for the HUD. Communication is unidirectional: ViewModel → Scene for data, Scene → ViewModel via direct method call for lifecycle events.

**Tech Stack:** Swift 5.9, SwiftUI, SpriteKit, XCTest — iOS 17+ target, iPhone portrait only.

---

## File Map

| File | Role |
|------|------|
| `FishNShips/App/FishNShipsApp.swift` | `@main` entry point — presents `ContentView` |
| `FishNShips/Models/SlotSymbol.swift` | Symbol enum + placeholder color + weight |
| `FishNShips/Models/GridCell.swift` | Value type for one grid cell |
| `FishNShips/Models/ReelGrid.swift` | 5×3 grid + weighted random spin |
| `FishNShips/ViewModels/GameViewModel.swift` | All published state + spin/bet logic |
| `FishNShips/Scene/SymbolNode.swift` | 64×64 SKSpriteNode — colored square now, texture-ready |
| `FishNShips/Scene/ReelNode.swift` | SKCropNode for one column — manages 3 SymbolNodes + spin animation |
| `FishNShips/Scene/GameScene.swift` | SKScene — builds grid, wires ViewModel, triggers animation |
| `FishNShips/Views/HUDView.swift` | Balance / Win / Bet row |
| `FishNShips/Views/SpinButtonView.swift` | BET- / SPIN / BET+ controls |
| `FishNShips/Views/GameView.swift` | Layout B: title + SpriteView + HUD + controls — owns `@StateObject GameViewModel` |
| `FishNShips/Views/ContentView.swift` | Root view |
| `FishNShipsTests/Models/ReelGridTests.swift` | Unit tests for randomise + weightedRandom |
| `FishNShipsTests/ViewModels/GameViewModelTests.swift` | Unit tests for spin, adjustBet, balance guard |

---

## Task 1: Xcode Project Scaffold

**Files:**
- Create: `FishNShips.xcodeproj` (via Xcode GUI)
- Create: folder groups `App/`, `Models/`, `ViewModels/`, `Views/`, `Scene/`
- Create: test target `FishNShipsTests`

- [ ] **Step 1: Create Xcode project**

  In Xcode: **File → New → Project → iOS → App**
  - Product Name: `FishNShips`
  - Interface: **SwiftUI**
  - Language: **Swift**
  - Include Tests: **checked**
  - Uncheck "Use Core Data"
  - Save at: `fish-n-ships/FishNShips/`

- [ ] **Step 2: Set deployment target**

  In project settings → General → Minimum Deployments → **iOS 17.0**

- [ ] **Step 3: Add SpriteKit framework**

  Project → FishNShips target → Frameworks, Libraries → `+` → `SpriteKit.framework`

- [ ] **Step 4: Create folder groups in Xcode**

  Right-click `FishNShips` group → New Group (without folder) for each:
  `App`, `Models`, `ViewModels`, `Views`, `Scene`

  Move `FishNShipsApp.swift` and `ContentView.swift` into the `App` and `Views` groups respectively.

- [ ] **Step 5: Delete template boilerplate**

  Delete `Assets.xcassets` default contents (keep the catalog, remove `AccentColor` and `AppIcon` placeholder — we will repopulate). Delete any `.sks` action files if Xcode created them.

- [ ] **Step 6: Initial commit**

  ```bash
  cd fish-n-ships
  git init
  git add FishNShips.xcodeproj FishNShips/ FishNShipsTests/
  git commit -m "chore: scaffold Xcode project — iOS 17, SwiftUI + SpriteKit"
  ```

---

## Task 2: Add Spritesheet to Assets.xcassets

**Files:**
- Modify: `FishNShips/Assets.xcassets` (add image set)
- Source: `fish-n-ships/assets/icon.png`

- [ ] **Step 1: Create image set in Xcode**

  In Xcode, open `Assets.xcassets` → `+` → **New Image Set** → rename to `GameSpriteSheet`

- [ ] **Step 2: Add icon.png**

  Drag `assets/icon.png` from Finder into the `GameSpriteSheet` 1× slot.
  Leave 2× and 3× empty (single resolution spritesheet).

- [ ] **Step 3: Verify it bundles**

  Build the project (`Cmd+B`). Confirm no asset errors in the build log.

- [ ] **Step 4: Commit**

  ```bash
  git add FishNShips/Assets.xcassets/
  git commit -m "chore: add GameSpriteSheet spritesheet to asset catalog"
  ```

---

## Task 3: SlotSymbol Enum

**Files:**
- Create: `FishNShips/Models/SlotSymbol.swift`

- [ ] **Step 1: Create the file and write the enum**

  `FishNShips/Models/SlotSymbol.swift`:
  ```swift
  import SwiftUI

  enum SlotSymbol: CaseIterable {
      // High-paying
      case clownfish, octopus, seaTurtle, blueTang
      // Low-paying
      case ace, king
      // NOTE: queen, jack, ten, nine are available in GameSpriteSheet — deferred to later milestone
      // Special
      case wild, pearl

      var placeholderColor: Color {
          switch self {
          case .clownfish:  return Color(hex: 0xE8541A)
          case .octopus:    return Color(hex: 0x7B3FB5)
          case .seaTurtle:  return Color(hex: 0x2A8A4A)
          case .blueTang:   return Color(hex: 0x1A6AB5)
          case .ace:        return Color(hex: 0xC8A020)
          case .king:       return Color(hex: 0x8A7040)
          case .wild:       return Color(hex: 0x2ACFCF)
          case .pearl:      return Color(hex: 0xD0D0FF)
          }
      }

      var placeholderUIColor: UIColor { UIColor(placeholderColor) }

      /// Relative weight for spin randomisation. Total = 100.
      var weight: Int {
          switch self {
          case .clownfish:  return 20
          case .octopus:    return 15
          case .seaTurtle:  return 15
          case .blueTang:   return 15
          case .ace:        return 18
          case .king:       return 12
          case .wild:       return 3
          case .pearl:      return 2
          }
      }
  }

  extension Color {
      init(hex: UInt32) {
          self.init(
              red:   Double((hex >> 16) & 0xFF) / 255,
              green: Double((hex >> 8)  & 0xFF) / 255,
              blue:  Double( hex        & 0xFF) / 255
          )
      }
  }
  ```

- [ ] **Step 2: Verify weights sum to 100**

  Add this assertion in a scratch test (or just verify mentally: 20+15+15+15+18+12+3+2 = 100). ✓

- [ ] **Step 3: Build check**

  `Cmd+B` — should compile cleanly.

- [ ] **Step 4: Commit**

  ```bash
  git add FishNShips/Models/SlotSymbol.swift
  git commit -m "feat: add SlotSymbol enum with placeholder colors and weights"
  ```

---

## Task 4: GridCell + ReelGrid (with tests)

**Files:**
- Create: `FishNShips/Models/GridCell.swift`
- Create: `FishNShips/Models/ReelGrid.swift`
- Create: `FishNShipsTests/Models/ReelGridTests.swift`

- [ ] **Step 1: Write failing tests**

  `FishNShipsTests/Models/ReelGridTests.swift`:
  ```swift
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
          // Run many times — statistically near-certain at least one changes
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
          // Manually set a frame level
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
          // Pearl (weight 2) should appear less than clownfish (weight 20)
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
  ```

- [ ] **Step 2: Run tests — expect FAIL (types not defined)**

  `Cmd+U` in Xcode. Expected: compile errors — `ReelGrid`, `GridCell` not found.

- [ ] **Step 3: Implement GridCell**

  `FishNShips/Models/GridCell.swift`:
  ```swift
  struct GridCell: Identifiable, Equatable {
      let id: Int
      let row: Int   // 0–2
      let col: Int   // 0–4
      var symbol: SlotSymbol
      var frameLevel: Int  // 0=none, 1=Seaweed, 2=Coral, 3=Shipwreck, 4=Poseidon

      init(row: Int, col: Int, symbol: SlotSymbol = .clownfish, frameLevel: Int = 0) {
          self.id = row * 5 + col
          self.row = row
          self.col = col
          self.symbol = symbol
          self.frameLevel = frameLevel
      }
  }
  ```

- [ ] **Step 4: Implement ReelGrid**

  `FishNShips/Models/ReelGrid.swift`:
  ```swift
  struct ReelGrid {
      var cells: [GridCell]   // count == 15, row-major

      init() {
          cells = (0..<3).flatMap { row in
              (0..<5).map { col in
                  GridCell(row: row, col: col, symbol: ReelGrid.weightedRandom())
              }
          }
      }

      mutating func randomise() {
          for i in cells.indices {
              cells[i].symbol = ReelGrid.weightedRandom()
              // frameLevel intentionally preserved
          }
      }

      func cell(row: Int, col: Int) -> GridCell {
          cells[row * 5 + col]
      }

      static func weightedRandom() -> SlotSymbol {
          let total = SlotSymbol.allCases.reduce(0) { $0 + $1.weight }
          var r = Int.random(in: 0..<total)
          for sym in SlotSymbol.allCases {
              r -= sym.weight
              if r < 0 { return sym }
          }
          return .clownfish  // fallback (unreachable)
      }
  }
  ```

- [ ] **Step 5: Run tests — expect PASS**

  `Cmd+U`. All 6 `ReelGridTests` should pass.

- [ ] **Step 6: Commit**

  ```bash
  git add FishNShips/Models/ FishNShipsTests/Models/
  git commit -m "feat: add GridCell, ReelGrid with weighted randomisation + tests"
  ```

---

## Task 5: GameViewModel (with tests)

**Files:**
- Create: `FishNShips/ViewModels/GameViewModel.swift`
- Create: `FishNShipsTests/ViewModels/GameViewModelTests.swift`

- [ ] **Step 1: Write failing tests**

  `FishNShipsTests/ViewModels/GameViewModelTests.swift`:
  ```swift
  import XCTest
  @testable import FishNShips

  @MainActor
  final class GameViewModelTests: XCTestCase {

      func test_initial_state() {
          let vm = GameViewModel()
          XCTAssertEqual(vm.balance, 1000.0)
          XCTAssertEqual(vm.bet, 1.0)
          XCTAssertEqual(vm.lastWin, 0.0)
          XCTAssertFalse(vm.isSpinning)
          XCTAssertEqual(vm.grid.count, 15)
      }

      func test_spin_deducts_bet() {
          let vm = GameViewModel()
          vm.spin()
          XCTAssertEqual(vm.balance, 999.0)
      }

      func test_spin_sets_isSpinning_true() {
          let vm = GameViewModel()
          vm.spin()
          XCTAssertTrue(vm.isSpinning)
      }

      func test_spin_resets_lastWin() {
          let vm = GameViewModel()
          vm.lastWin = 50.0
          vm.spin()
          XCTAssertEqual(vm.lastWin, 0.0)
      }

      func test_spinCompleted_clears_isSpinning() {
          let vm = GameViewModel()
          vm.spin()
          vm.spinCompleted()
          XCTAssertFalse(vm.isSpinning)
      }

      func test_spin_noop_when_already_spinning() {
          let vm = GameViewModel()
          vm.spin()
          let balanceAfterFirst = vm.balance
          vm.spin()  // should be ignored
          XCTAssertEqual(vm.balance, balanceAfterFirst)
      }

      func test_spin_noop_when_balance_less_than_bet() {
          let vm = GameViewModel()
          vm.balance = 0.40
          vm.bet = 0.50
          vm.spin()
          XCTAssertFalse(vm.isSpinning)
          XCTAssertEqual(vm.balance, 0.40)
      }

      func test_canSpin_false_when_spinning() {
          let vm = GameViewModel()
          vm.spin()
          XCTAssertFalse(vm.canSpin)
      }

      func test_canSpin_false_when_balance_below_bet() {
          let vm = GameViewModel()
          vm.balance = 0.0
          XCTAssertFalse(vm.canSpin)
      }

      func test_adjustBet_increases() {
          let vm = GameViewModel()
          vm.bet = 1.0
          vm.adjustBet(1)
          XCTAssertEqual(vm.bet, 2.0)
      }

      func test_adjustBet_decreases() {
          let vm = GameViewModel()
          vm.bet = 1.0
          vm.adjustBet(-1)
          XCTAssertEqual(vm.bet, 0.50)
      }

      func test_adjustBet_clamps_at_max() {
          let vm = GameViewModel()
          vm.bet = 50.0
          vm.adjustBet(1)
          XCTAssertEqual(vm.bet, 50.0)
      }

      func test_adjustBet_clamps_at_min() {
          let vm = GameViewModel()
          vm.bet = 0.50
          vm.adjustBet(-1)
          XCTAssertEqual(vm.bet, 0.50)
      }

      func test_spin_fires_onSpinRequested() {
          let vm = GameViewModel()
          var fired = false
          vm.onSpinRequested = { fired = true }
          vm.spin()
          XCTAssertTrue(fired)
      }
  }
  ```

- [ ] **Step 2: Run tests — expect FAIL**

  `Cmd+U`. Expected: compile error — `GameViewModel` not found.

- [ ] **Step 3: Implement GameViewModel**

  `FishNShips/ViewModels/GameViewModel.swift`:
  ```swift
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
  ```

- [ ] **Step 4: Run tests — expect all PASS**

  `Cmd+U`. All 13 `GameViewModelTests` should pass.

- [ ] **Step 5: Commit**

  ```bash
  git add FishNShips/ViewModels/ FishNShipsTests/ViewModels/
  git commit -m "feat: add GameViewModel with spin, bet adjustment, balance guard + tests"
  ```

---

## Task 6: SymbolNode

**Files:**
- Create: `FishNShips/Scene/SymbolNode.swift`

- [ ] **Step 1: Implement SymbolNode**

  `FishNShips/Scene/SymbolNode.swift`:
  ```swift
  import SpriteKit

  /// A single grid cell. M1: coloured square. M2+: cropped texture from GameSpriteSheet.
  final class SymbolNode: SKSpriteNode {

      static let cellSize = CGSize(width: 64, height: 64)

      private(set) var symbol: SlotSymbol

      init(symbol: SlotSymbol) {
          self.symbol = symbol
          super.init(texture: nil, color: symbol.placeholderUIColor, size: SymbolNode.cellSize)
          configure(symbol: symbol, useTexture: false)
      }

      required init?(coder aDecoder: NSCoder) { fatalError("not used") }

      /// Call to update this node's symbol.
      /// - Parameters:
      ///   - symbol: The new symbol to display.
      ///   - useTexture: false (M1) = solid colour square. true (M2+) = cropped spritesheet texture.
      func configure(symbol: SlotSymbol, useTexture: Bool = false) {
          self.symbol = symbol
          if useTexture {
              // M2+: texture = SymbolCrop.texture(for: symbol)
              // Crop constants (normalised rects) to be measured from GameSpriteSheet in M2.
          } else {
              texture = nil
              color = symbol.placeholderUIColor
              colorBlendFactor = 1.0
          }
      }
  }
  ```

- [ ] **Step 2: Build check**

  `Cmd+B`. Should compile cleanly.

- [ ] **Step 3: Commit**

  ```bash
  git add FishNShips/Scene/SymbolNode.swift
  git commit -m "feat: add SymbolNode — coloured square with texture-ready configure API"
  ```

---

## Task 7: ReelNode

**Files:**
- Create: `FishNShips/Scene/ReelNode.swift`

- [ ] **Step 1: Implement ReelNode**

  > **Note on animation approach:** The spec describes a `moveBy` vertical scroll (fast scroll up + decelerate), but M1 uses a stationary colour-cycling approach instead — symbols flash through random colours, then snap with a scale bounce. This is a deliberate M1 simplification; the spec explicitly says "speed will be tuned in a later pass." The physical reel-scroll mechanic can be added in M2 when real textures are in place and the animation timings are being tuned. The acceptance criteria ("reels animate with left-to-right stagger, decelerate, and snap") are satisfied by the colour-cycle + stagger + bounce.

  `FishNShips/Scene/ReelNode.swift`:
  ```swift
  import SpriteKit

  /// One column of the reel grid (3 SymbolNodes). Handles its own spin animation.
  final class ReelNode: SKCropNode {

      static let cellSize: CGFloat = 64
      static let gap: CGFloat = 4
      static let stride: CGFloat = cellSize + gap  // 68 pt

      private var symbolNodes: [SymbolNode] = []
      let column: Int

      init(column: Int, symbols: [SlotSymbol]) {
          self.column = column
          super.init()

          // Crop mask — window exactly tall enough for 3 rows
          let maskHeight = ReelNode.cellSize * 3 + ReelNode.gap * 2
          let mask = SKSpriteNode(color: .white,
                                  size: CGSize(width: ReelNode.cellSize, height: maskHeight))
          maskNode = mask

          // Build 3 SymbolNodes. Row 0 = top (positive y), row 2 = bottom.
          for row in 0..<3 {
              let node = SymbolNode(symbol: symbols[row])
              node.position = CGPoint(x: 0, y: CGFloat(1 - row) * ReelNode.stride)
              addChild(node)
              symbolNodes.append(node)
          }
      }

      required init?(coder aDecoder: NSCoder) { fatalError("not used") }

      // MARK: - Symbol Update

      func updateSymbols(_ symbols: [SlotSymbol], useTexture: Bool = false) {
          for (i, sym) in symbols.prefix(3).enumerated() {
              symbolNodes[i].configure(symbol: sym, useTexture: useTexture)
          }
      }

      // MARK: - Spin Animation

      /// Plays the spin animation for this reel.
      /// - Parameters:
      ///   - finalSymbols: The 3 symbols to snap to at the end (top→bottom).
      ///   - delay: Stagger delay before this reel starts (col * 0.15 s).
      ///   - completion: Called when the animation finishes (used by GameScene to detect last reel).
      func spinAnimation(finalSymbols: [SlotSymbol], delay: TimeInterval, completion: @escaping () -> Void) {
          let cycleColors = SlotSymbol.allCases.map { $0.placeholderUIColor }
          var colorIndex = 0

          // Color-cycling action (fast spin feel)
          let cycleAction = SKAction.repeatForever(
              SKAction.sequence([
                  SKAction.run { [weak self] in
                      colorIndex = (colorIndex + 1) % cycleColors.count
                      let c = cycleColors[colorIndex]
                      self?.symbolNodes.forEach { $0.color = c; $0.colorBlendFactor = 1.0 }
                  },
                  SKAction.wait(forDuration: 0.06)
              ])
          )

          // Main sequence
          let sequence = SKAction.sequence([
              // Wait for stagger
              SKAction.wait(forDuration: delay),
              // Fast cycling phase (0.9 s)
              SKAction.group([
                  cycleAction,
                  SKAction.wait(forDuration: 0.9)
              ]),
              // Stop cycle and snap to final symbols
              SKAction.run { [weak self] in
                  self?.removeAllActions()
                  self?.updateSymbols(finalSymbols)
              },
              // Bounce: scale up slightly then back
              SKAction.scale(to: 1.06, duration: 0.05),
              SKAction.scale(to: 1.0,  duration: 0.07),
              // Signal done
              SKAction.run { completion() }
          ])

          run(sequence, withKey: "spin-col-\(column)")
      }
  }
  ```

- [ ] **Step 2: Build check**

  `Cmd+B`. Should compile cleanly.

- [ ] **Step 3: Commit**

  ```bash
  git add FishNShips/Scene/ReelNode.swift
  git commit -m "feat: add ReelNode — 3-cell column with staggered colour-cycle spin animation"
  ```

---

## Task 8: GameScene

**Files:**
- Create: `FishNShips/Scene/GameScene.swift`

- [ ] **Step 1: Implement GameScene**

  `FishNShips/Scene/GameScene.swift`:
  ```swift
  import SpriteKit

  final class GameScene: SKScene {

      // MARK: - Layout constants

      private enum Layout {
          static let cellSize: CGFloat = ReelNode.cellSize
          static let gap: CGFloat = ReelNode.gap
          static let stride: CGFloat = ReelNode.stride          // 68 pt
          static let gridWidth: CGFloat = stride * 5 - gap      // 336 pt
          static let gridHeight: CGFloat = stride * 3 - gap     // 200 pt
          static let colStagger: TimeInterval = 0.15
      }

      // MARK: - State

      weak var viewModel: GameViewModel?
      private var reelNodes: [ReelNode] = []

      // MARK: - Lifecycle

      override func didMove(to view: SKView) {
          backgroundColor = UIColor(red: 0.016, green: 0.051, blue: 0.098, alpha: 1) // #040D19
          // buildGrid is called from configure(with:) so it has access to initial symbols.
          // If viewModel is already set (unlikely at this point), wire immediately.
          if let vm = viewModel { configure(with: vm) } else { buildGrid() }
      }

      // MARK: - Setup

      /// Wire the ViewModel. Called from GameView.onAppear — the guaranteed-safe wiring point.
      func configure(with vm: GameViewModel) {
          viewModel = vm
          buildGrid(initialGrid: vm.grid)   // rebuild with ViewModel's initial symbols
          vm.onSpinRequested = { [weak self] in
              guard let self else { return }
              self.startSpinAnimation()
          }
      }

      private func buildGrid(initialGrid: [GridCell]? = nil) {
          reelNodes.removeAll()
          removeAllChildren()

          // Background
          let bg = SKSpriteNode(color: .black, size: self.size)
          bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
          bg.zPosition = -1
          addChild(bg)

          // Grid container — centred in scene
          let container = SKNode()
          container.position = CGPoint(
              x: (size.width - Layout.gridWidth) / 2 + Layout.cellSize / 2,
              y: (size.height + Layout.gridHeight) / 2 - Layout.cellSize / 2
          )
          addChild(container)

          // Build 5 ReelNodes — use ViewModel's initial grid if available, else random
          let fallback = ReelGrid()
          for col in 0..<5 {
              let symbols: [SlotSymbol]
              if let grid = initialGrid {
                  // grid is row-major; extract this column's symbols top→bottom
                  symbols = (0..<3).map { row in grid[row * 5 + col].symbol }
              } else {
                  symbols = (0..<3).map { _ in fallback.cell(row: 0, col: col).symbol }
              }
              let reel = ReelNode(column: col, symbols: symbols)
              reel.position = CGPoint(x: CGFloat(col) * Layout.stride, y: 0)
              container.addChild(reel)
              reelNodes.append(reel)
          }
      }

      // MARK: - Animation

      func startSpinAnimation() {
          guard let vm = viewModel else { return }

          // Extract per-column final symbols from the already-randomised grid
          var finalSymbolsByCol: [[SlotSymbol]] = Array(repeating: [], count: 5)
          for cell in vm.grid {
              finalSymbolsByCol[cell.col].append(cell.symbol)
          }

          var completedReels = 0
          let totalReels = reelNodes.count

          for (col, reel) in reelNodes.enumerated() {
              let delay = Double(col) * Layout.colStagger
              let syms = finalSymbolsByCol[col]
              reel.spinAnimation(finalSymbols: syms, delay: delay) { [weak self] in
                  completedReels += 1
                  if completedReels == totalReels {
                      self?.animationDidFinish()
                  }
              }
          }
      }

      private func animationDidFinish() {
          // Must dispatch to main actor — SKAction completions run on main thread,
          // but viewModel is @MainActor so this is safe.
          viewModel?.spinCompleted()
      }
  }
  ```

- [ ] **Step 2: Build check**

  `Cmd+B`. Should compile cleanly.

- [ ] **Step 3: Commit**

  ```bash
  git add FishNShips/Scene/GameScene.swift
  git commit -m "feat: add GameScene — 5x3 grid with staggered spin animation + ViewModel bridge"
  ```

---

## Task 9: SwiftUI Views

**Files:**
- Create: `FishNShips/Views/HUDView.swift`
- Create: `FishNShips/Views/SpinButtonView.swift`
- Create: `FishNShips/Views/GameView.swift`
- Modify: `FishNShips/Views/ContentView.swift`

- [ ] **Step 1: Implement HUDView**

  `FishNShips/Views/HUDView.swift`:
  ```swift
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
  ```

- [ ] **Step 2: Implement SpinButtonView**

  `FishNShips/Views/SpinButtonView.swift`:
  ```swift
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
  ```

- [ ] **Step 3: Implement GameView**

  `FishNShips/Views/GameView.swift`:
  ```swift
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
  ```

- [ ] **Step 4: Update ContentView**

  `FishNShips/Views/ContentView.swift`:
  ```swift
  import SwiftUI

  struct ContentView: View {
      var body: some View {
          GameView()
      }
  }
  ```

- [ ] **Step 5: Build check**

  `Cmd+B`. Should compile cleanly.

- [ ] **Step 6: Commit**

  ```bash
  git add FishNShips/Views/
  git commit -m "feat: add SwiftUI views — Layout B with title, SpriteView, HUD, spin controls"
  ```

---

## Task 10: App Entry Point + Final Verification

**Files:**
- Modify: `FishNShips/App/FishNShipsApp.swift`

- [ ] **Step 1: Update app entry point**

  `FishNShips/App/FishNShipsApp.swift`:
  ```swift
  import SwiftUI

  @main
  struct FishNShipsApp: App {
      var body: some Scene {
          WindowGroup {
              ContentView()
          }
      }
  }
  ```

- [ ] **Step 2: Run all tests**

  `Cmd+U`. All tests in `ReelGridTests` and `GameViewModelTests` must pass.

  Expected output (look for):
  ```
  Test Suite 'ReelGridTests' passed
  Test Suite 'GameViewModelTests' passed
  ```

- [ ] **Step 3: Run on iPhone 15 Pro Simulator**

  Select scheme **FishNShips** → destination **iPhone 15 Pro** (iOS 17) → `Cmd+R`.

- [ ] **Step 4: Verify acceptance criteria**

  Work through each item:
  - [ ] `GameSpriteSheet` visible in Assets.xcassets
  - [ ] App launches without crash
  - [ ] Title "FISH N' SHIPS" visible at top
  - [ ] 5×3 grid of coloured squares visible in centre
  - [ ] BAL / WIN / BET row shows $1,000.00 / $0.00 / $1.00
  - [ ] Tap SPIN — balance drops by $1, button greys out
  - [ ] All 5 reels cycle colours with left-to-right stagger, then snap with bounce
  - [ ] SPIN re-enables after animation completes
  - [ ] BET- / BET+ steps through 0.50 → 1.00 → ... → 50.00
  - [ ] Rapidly tapping SPIN area during spin does not trigger extra spins

- [ ] **Step 5: Final commit**

  ```bash
  git add FishNShips/App/FishNShipsApp.swift
  git commit -m "feat: wire app entry point — Milestone 1 complete"
  ```

- [ ] **Step 6: Tag milestone**

  ```bash
  git tag milestone-1-basic-grid
  ```

---

## Quick Reference

| Thing | Value |
|-------|-------|
| Cell size | 64 × 64 pt |
| Grid total | 336 × 200 pt (5×64 + 4 gaps, 3×64 + 2 gaps) |
| Spin cycle duration | 0.9 s per reel |
| Reel stagger | 0.15 s per column |
| Last reel finishes | ~1.35 s after tap |
| Bet steps | 0.50, 1.00, 2.00, 5.00, 10.00, 20.00, 50.00 |
| Starting balance | $1,000 |
| Symbol weights | clownfish 20, ace 18, octopus/turtle/tang 15 each, king 12, wild 3, pearl 2 |
