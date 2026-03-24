# Fish N' Ships — Agent Context

## Project Overview

**Fish N' Ships** is a native iOS slot machine game with a deep-sea pixel-art theme. Built with Swift, SwiftUI, and SpriteKit. Currently at **Milestone 1 (MVP)** — fully playable prototype with spin mechanics, balance management, and animated reels. Win detection and real assets are deferred to future milestones.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI | SwiftUI (layout, HUD, controls) |
| Game engine | SpriteKit (5×3 reel grid, animations) |
| Architecture | MVVM |
| Testing | XCTest |
| Build config | XcodeGen (`project.yml`) |
| Platform | iOS 17.0+, iPhone portrait only |
| Dependencies | SpriteKit.framework (bundled — no external packages) |

---

## Repository Layout

```
fish-n-ships/
├── FishNShips/
│   ├── App/
│   │   └── FishNShipsApp.swift        # @main entry point
│   ├── Models/
│   │   ├── SlotSymbol.swift           # Symbol enum with weights & placeholder colors
│   │   ├── GridCell.swift             # Single cell (symbol, row, col, frame level)
│   │   └── ReelGrid.swift             # 5×3 grid with weighted randomization
│   ├── ViewModels/
│   │   └── GameViewModel.swift        # @MainActor observable state (balance, bet, spin)
│   ├── Views/
│   │   ├── ContentView.swift          # Root SwiftUI view
│   │   ├── GameView.swift             # Layout B: title + SpriteView + HUD + controls
│   │   ├── HUDView.swift              # Balance | Win | Bet display
│   │   └── SpinButtonView.swift       # BET- / SPIN / BET+ controls
│   ├── Scene/
│   │   ├── GameScene.swift            # SpriteKit scene, grid orchestration
│   │   ├── ReelNode.swift             # One reel column (3 cells, SKCropNode)
│   │   └── SymbolNode.swift           # One 64×64 pt cell (texture-ready)
│   └── Assets.xcassets/               # GameSpriteSheet asset catalog
├── FishNShipsTests/
│   ├── Models/
│   │   └── ReelGridTests.swift        # 5 tests: grid structure & weighted distribution
│   └── ViewModels/
│       └── GameViewModelTests.swift   # 11 tests: spin, bet, balance guard
├── docs/
│   └── superpowers/
│       ├── specs/                     # Design specifications
│       └── plans/                     # Implementation plans
└── project.yml                        # XcodeGen project definition
```

---

## Architecture

MVVM with a SpriteKit hybrid layer:

```
SwiftUI Views  ←──(observe)──  GameViewModel (@MainActor)
                                    │
                              onSpinRequested()  ←── callback set by GameScene
                                    │
                               GameScene (SpriteKit)
                                    │
                              viewModel.spinCompleted()  ──→ updates state
```

- **ViewModel owns all state.** SpriteKit scene holds a `weak` reference.
- SwiftUI views read published properties (`@StateObject` / `@ObservedObject`).
- Communication is unidirectional: ViewModel triggers animation via callback; Scene reports completion via direct method call.

---

## Key Domain Concepts

### Symbols (`SlotSymbol`)

8 symbols with configurable weights for randomization:

| Symbol | Weight | Color (placeholder) |
|---|---|---|
| clownfish | 20 | orange |
| octopus | 15 | purple |
| seaTurtle | 15 | green |
| blueTang | 15 | blue |
| ace | 12 | gold |
| king | 12 | brown |
| wild | 6 | cyan |
| pearl | 5 | lavender |

### Grid

- 5 reels × 3 rows = 15 cells
- `ReelGrid` produces a randomized `[[GridCell]]` on each spin using weighted selection
- `GridCell` stores symbol, row, column, and `frameLevel` (reserved for future pearl/frame mechanic)

### GameViewModel state

| Property | Initial | Notes |
|---|---|---|
| `balance` | 1000.00 | Deducted on each spin |
| `bet` | 0.50 | Steps: 0.50 / 1 / 2 / 5 / 10 / 20 / 50 |
| `lastWin` | 0.00 | Always 0 — win logic not yet implemented |
| `isSpinning` | false | Guard prevents concurrent spins |
| `grid` | empty | Updated by `spinCompleted()` |

---

## Build & Run

**Prerequisites:** Xcode 15.4+, XcodeGen (optional if `.xcodeproj` already exists)

```bash
# Regenerate project file (only needed after project.yml changes)
xcodegen generate

# Open in Xcode
open FishNShips.xcodeproj
# Cmd+R  →  run on iOS 17+ Simulator (iPhone 15 Pro recommended)
```

---

## Testing

```bash
# In Xcode
Cmd+U

# Command line
xcodebuild test -scheme FishNShips -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

16 unit tests total (no UI tests yet):
- `ReelGridTests` — grid dimensions, randomization, weighted distribution
- `GameViewModelTests` — initial state, spin deductions, bet clamping, balance guard

All tests are pure logic tests; no simulator required to run them.

---

## What Is and Isn't Implemented

### Done (Milestone 1)
- Xcode project scaffold (XcodeGen)
- Data models: SlotSymbol, GridCell, ReelGrid
- GameViewModel with balance, bet, spin state
- SwiftUI Layout B (title + SpriteView + HUD + controls)
- SpriteKit 5×3 grid with staggered color-cycling spin animation
- 16 unit tests

### Deferred to Future Milestones
- Win detection and pay table
- Real pixel-art sprite assets (currently solid-color placeholders)
- Pearl / frame / build mechanic
- Bonus game ("Kraken's Awakening")
- Sound effects and music
- Data persistence (balance resets on launch)
- Landscape orientation support
- Additional symbols (Queen, Jack, 10, 9)

---

## Key Constants

| Constant | Value | Location |
|---|---|---|
| Cell size | 64×64 pt | `SymbolNode.swift` |
| Grid gap | 4 pt | `GameScene.swift` |
| Reel stagger delay | 0.15 s | `GameScene.swift` |
| Spin duration per reel | ~0.9 s | `ReelNode.swift` |
| Background color | `#040D19` | `GameScene.swift` |
| SPIN button color | `#C8860A` | `SpinButtonView.swift` |

---

## No Backend / No Environment Variables

This is a fully offline, self-contained app. No API keys, no network calls, no database, no environment variables needed.
