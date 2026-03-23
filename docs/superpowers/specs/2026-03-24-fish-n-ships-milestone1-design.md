# Fish N' Ships — Milestone 1 Design Spec
**Date:** 2026-03-24
**Scope:** Project initialisation, basic 5×3 reel grid, dummy spin animation

---

## 1. Overview

Build the foundational iOS native slot machine game "Fish N' Ships" — a deep-sea pixel art slot inspired by the "Huff N' Even More Puff" build mechanic. Milestone 1 delivers a runnable Xcode project with a working game screen layout, a 5×3 SpriteKit reel grid, and a placeholder spin animation. No win logic, no real assets, no bonus game.

**Tech stack:**
- Language: Swift
- Game engine: SpriteKit (reel grid, symbols, animation)
- UI framework: SwiftUI (HUD, buttons, layout)
- Architecture: MVVM (ViewModel-Driven, Approach A)
- Target: iOS 17+, iPhone portrait

---

## 2. Project Structure

```
FishNShips/
  App/
    FishNShipsApp.swift       // @main entry point
  Models/
    SlotSymbol.swift          // enum of all symbol types + placeholder color
    GridCell.swift            // struct: id, row, col, symbol, frameLevel
    ReelGrid.swift            // 5×3 grid of GridCell, spin randomisation
  ViewModels/
    GameViewModel.swift       // @MainActor ObservableObject — owns all state
  Views/
    ContentView.swift         // root SwiftUI view
    GameView.swift            // Layout B: title + SpriteView + HUD row + controls
    HUDView.swift             // Balance / Win / Bet info row
    SpinButtonView.swift      // BET- / SPIN / BET+ controls
  Scene/
    GameScene.swift           // SKScene — draws and animates the 5×3 grid
    ReelNode.swift            // SKNode for one reel column (3 cells + crop mask)
    SymbolNode.swift          // SKSpriteNode for one cell (coloured square)
```

---

## 3. Screen Layout (Layout B — Title + Win Row)

Portrait iPhone layout, top to bottom:

1. **Title bar** — "FISH N' SHIPS" centred, pixel-art style font (system bold for M1)
2. **SpriteKit view** — fills available centre space, contains the 5×3 reel grid
3. **HUD row** — three columns: BAL (balance) | WIN (last win) | BET (current bet)
4. **Controls row** — BET- button | SPIN button | BET+ button

---

## 4. Data Model

### SlotSymbol (enum)
All cases are `CaseIterable`. Each provides a `placeholderColor: Color` for M1 rendering.

| Symbol     | Type          | Placeholder colour |
|------------|---------------|--------------------|
| clownfish  | High pay      | Orange `#E8541A`   |
| octopus    | High pay      | Purple `#7B3FB5`   |
| seaTurtle  | High pay      | Green  `#2A8A4A`   |
| blueTang   | High pay      | Blue   `#1A6AB5`   |
| ace        | Low pay       | Gold   `#C8A020`   |
| king       | Low pay       | Brown  `#8A7040`   |
<!-- NOTE: The spritesheet also contains queen, jack, ten (10), nine (9) low-pay symbols. Deferred — decide in a later milestone whether to expand the symbol set. -->
| wild       | Special (sub) | Cyan   `#2ACFCF`   |
| pearl      | Scatter       | Lavender `#D0D0FF` |

### GridCell (struct)
```
id: Int          // 0–14, row-major: row*5 + col
row: Int         // 0–2
col: Int         // 0–4
symbol: SlotSymbol
frameLevel: Int  // 0=none, 1=Seaweed, 2=Coral, 3=Shipwreck, 4=Poseidon
```

### ReelGrid
Holds `[GridCell]` (count == 15). Exposes `randomise()` which assigns a weighted random symbol to each cell. `frameLevel` values are preserved across spins (not reset — used in later milestones).

---

## 5. GameViewModel

`@MainActor class GameViewModel: ObservableObject`

### Published state
| Property      | Type    | Initial value |
|---------------|---------|---------------|
| `balance`     | Double  | 1000.0        |
| `bet`         | Double  | 1.0           |
| `lastWin`     | Double  | 0.0           |
| `grid`        | [GridCell] | 15 cells, random symbols |
| `isSpinning`  | Bool    | false         |

### Bet steps
`[0.50, 1.00, 2.00, 5.00, 10.00, 20.00, 50.00]` — `adjustBet(_:)` steps through this array, clamped at min/max.

### Methods
- `spin()` — deduct bet from balance, randomise grid, set `isSpinning = true`, call `onSpinRequested?()`. Guard: no-op if `balance < bet`.
- `spinCompleted()` — set `isSpinning = false` (called by GameScene when animation finishes)
- `adjustBet(_ delta: Int)` — move up/down the bet steps array

### SPIN button disabled conditions
The SPIN button is disabled when **either** `isSpinning == true` **or** `balance < bet`.

### Callbacks (set by GameScene)
- `onSpinRequested: (() -> Void)?` — scene starts animation when this fires. Set by `GameScene.configure(with:)`.
- `onSpinCompleted` — not declared in M1. Scene calls `vm.spinCompleted()` directly. Callback scaffolding can be added in a future milestone if needed.

---

## 6. SpriteKit Scene

### Node hierarchy
```
GameScene (SKScene)
  backgroundNode (SKSpriteNode — solid dark blue #040D1A)
  gridContainer (SKNode — centred)
    ReelNode[0..4] (SKCropNode per column)
      SymbolNode[0..2] (SKSpriteNode — 64×64 pt coloured square)
```

### Sizing
- Symbol cell: **64 × 64 pt**, gap: **4 pt**
- Grid total: **336 × 200 pt** (5×64 cells + 4 gaps, 3×64 cells + 2 gaps)
- Grid centred in scene bounds

### ViewModel bridge
```swift
class GameScene: SKScene {
    weak var viewModel: GameViewModel?

    func configure(with vm: GameViewModel) {
        viewModel = vm
        vm.onSpinRequested = { [weak self] in self?.startSpinAnimation() }
    }

    private func animationDidFinish() {
        viewModel?.spinCompleted()
    }
}
```
`GameScene` is instantiated with a custom `init(viewModel:)` (or the ViewModel is assigned before the scene is presented). Wiring happens in `didMove(to:)` — the earliest safe point where the scene is live — by calling `self.configure(with: viewModel)`.

---

## 7. Spin Animation

Each of the 5 reel columns animates sequentially (left to right, **0.15 s stagger**).

Per-reel sequence (total ~1.0 s per reel):

| Phase | Duration | Action |
|-------|----------|--------|
| Fast scroll | 0.5 s | `SKAction.moveBy(y:)` easeIn — symbols blur upward, ghost cells cycle through random colours |
| Decelerate | 0.4 s | `SKAction.moveBy(y:)` easeOut — reel slows to final position |
| Snap & bounce | ~0.1 s | Small +4 pt overshoot then snap back; symbol colours update to final randomised values |

- Reel 0 starts at t=0, Reel 4 finishes at **~1.75 s**
- `animationDidFinish()` fires after Reel 4 completes → `vm.spinCompleted()`
- `SPIN` button is disabled (`isSpinning == true`) for the full duration

Speed will be tuned in a later pass — M1 values are a starting baseline.

---

## 8. Asset Spritesheet

A pixel-art spritesheet is provided at `assets/icon.png`. It contains all game symbols, frame tiers, and UI elements. It must be added to the Xcode project's **Assets.xcassets** as `GameSpriteSheet` so it is bundled with the app.

### Symbol crop regions (normalised UV coords, origin bottom-left)
These are the approximate regions to slice per symbol using `SKTexture(rect:in:)`. Exact values to be measured from the PNG dimensions in M2 — listed here as named constants so the implementation can stub them immediately.

| Symbol | Constant name |
|--------|--------------|
| clownfish | `SymbolCrop.clownfish` |
| octopus | `SymbolCrop.octopus` |
| seaTurtle | `SymbolCrop.seaTurtle` |
| blueTang | `SymbolCrop.blueTang` |
| ace | `SymbolCrop.ace` |
| king | `SymbolCrop.king` |
| queen | `SymbolCrop.queen` |
| jack | `SymbolCrop.jack` |
| wild | `SymbolCrop.wild` |
| pearl | `SymbolCrop.pearl` |

### SymbolNode texture-ready design
`SymbolNode` exposes a `configure(symbol:useTexture:)` method:
- `useTexture: false` (M1) — renders a 64×64 solid `SKSpriteNode` using `symbol.placeholderColor`
- `useTexture: true` (M2+) — loads `GameSpriteSheet` texture once (shared), crops the symbol rect, applies it

This keeps the M1→M2 asset swap to a single flag change.

## 9. What Milestone 1 Does NOT Include

- Win detection or pay table
- Real pixel art assets (placeholder coloured squares only)
- Pearl / frame / build mechanic
- Bonus game ("Kraken's Awakening")
- Sound effects or music
- Persistence (balance resets on app launch)
- Landscape orientation

---

## 10. Acceptance Criteria

- [ ] `assets/icon.png` is present in Assets.xcassets as `GameSpriteSheet`
- [ ] Xcode project builds and runs on iOS 17 Simulator (iPhone 15 Pro)
- [ ] Layout B is visible: title, SpriteKit view, HUD row, controls
- [ ] 5×3 grid of coloured squares renders correctly in the SpriteKit view
- [ ] Tapping SPIN deducts $1 from balance and disables the button
- [ ] All 5 reels animate with left-to-right stagger, decelerate, and snap
- [ ] SPIN re-enables after animation completes
- [ ] BET- / BET+ step through the defined bet values correctly
- [ ] No crashes on rapid SPIN taps (button correctly disabled during spin)
