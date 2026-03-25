# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Fish N' Ships** — an iOS native slot machine game. Deep-sea pixel art theme, inspired by a "build mechanic" slot. Currently at Milestone 1 (basic grid + placeholder spin animation). Target: iOS 17+, iPhone portrait only.

Tech stack: Swift 5.9 · SpriteKit (reel grid, animation) · SwiftUI (HUD, layout) · MVVM · xtool (WSL build/deploy)

---

## Build

Two build paths are supported.

### xtool (WSL/Linux)

[xtool](https://xtool.sh) builds and sideloads the app from WSL without a Mac. It uses **SwiftPM** (`Package.swift` + `xtool.yml`).

```bash
# Build and deploy to a connected physical iOS device
xtool dev

# Build only (no deploy)
swift build --swift-sdk arm64-apple-ios
```

`xtool dev` handles code signing automatically on first run (connects to Apple Developer Services, generates a certificate + provisioning profile). The device must be connected via USB.

### Xcode (macOS)

The Xcode project is generated from `project.yml` using [XcodeGen](https://github.com/yonaskolb/XcodeGen). Regenerate after editing `project.yml`:

```bash
xcodegen generate
```

Build and test from the command line:

```bash
# Build for simulator
xcodebuild -project FishNShips.xcodeproj -scheme FishNShips -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Run all tests
xcodebuild -project FishNShips.xcodeproj -scheme FishNShips -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test

# Run a single test class
xcodebuild -project FishNShips.xcodeproj -scheme FishNShips -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test -only-testing:FishNShipsTests/ReelGridTests
```

Tests live under `FishNShipsTests/` and mirror the `Models/` and `ViewModels/` source groups. The `Scene/` layer has no unit tests (SpriteKit nodes require a running SKView).

---

## Architecture

### Layer overview

```
Models/          Pure Swift structs/enums — no UIKit/SwiftUI dependency
ViewModels/      @MainActor ObservableObject — owns all published game state
Views/           SwiftUI — reads ViewModel, sends user actions down
Scene/           SpriteKit — renders the reel grid, drives spin animation
```

### SwiftUI ↔ SpriteKit wiring

`GameView` creates `GameScene` once and holds it for the app's lifetime. The wiring happens in `GameView.onAppear` (not in `GameScene.didMove(to:)` — that fires too early, before the ViewModel is set):

```swift
scene.configure(with: viewModel)
```

`configure(with:)` assigns `vm.onSpinRequested` — a closure the ViewModel calls when `spin()` is invoked. The scene calls `vm.spinCompleted()` directly when the animation finishes. There is no reverse callback declaration; the scene holds a `weak var viewModel`.

### Data flow for a spin

1. User taps SPIN → `viewModel.spin()` → deducts bet, randomises `ReelGrid`, sets `isSpinning = true`, fires `onSpinRequested?()`
2. `GameScene.startSpinAnimation()` runs per-reel animations with 0.15 s left-to-right stagger
3. When the last reel finishes → `animationDidFinish()` → `vm.spinCompleted()` → `isSpinning = false`

### Grid coordinate convention

`ReelGrid.cells` is a flat array of 15 `GridCell`, stored **row-major**: `cells[row * 5 + col]`. When `GameScene` extracts per-column symbols it must transpose: `(0..<3).map { row in grid[row * 5 + col].symbol }`.

### Key types

| Type | Role |
|---|---|
| `SlotSymbol` | `CaseIterable` enum; carries `placeholderColor` and `weight` for weighted randomisation |
| `GridCell` | `struct`; holds `frameLevel` (0–4, for future build mechanic) — preserved across `randomise()` calls |
| `ReelGrid` | Value type; `mutating randomise()` replaces symbols, never resets `frameLevel` |
| `GameViewModel` | Single source of truth; `canSpin` computed from `isSpinning` and `balance >= bet` |
| `ReelNode` | `SKCropNode` — the crop mask creates the reel window; handles its own spin animation |
| `SymbolNode` | `SKSpriteNode`; `configure(symbol:useTexture:)` — `useTexture: false` (M1 placeholder colours), `useTexture: true` (M2+ spritesheet) |

### Milestone 1 placeholder vs M2+ texture path

`SymbolNode.configure(useTexture: false)` renders a 64×64 solid colour square. The M2 upgrade is a single flag change — the `GameSpriteSheet` asset is already bundled in `Assets.xcassets` and `SymbolCrop` constants are stubbed for future normalised UV crop rects.

---

## Specs and plans

Design specs and implementation plans live under `docs/superpowers/`:
- `specs/` — milestone design documents (source of truth for intended behaviour)
- `plans/` — step-by-step implementation plans generated during development
