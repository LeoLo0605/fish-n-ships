# Milestone 2 — Sprite Assets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all placeholder coloured squares, buttons, and title text with pixel-art sprite assets from pre-cropped PNGs in `assets/sprites/`.

**Architecture:** Individual PNG files from `assets/sprites/` are registered as named image sets in `Assets.xcassets`. `SKTexture(imageNamed:)` loads them by name in `SymbolNode`. `SlotSymbol` gains 4 new cases and an `imageName` property. SwiftUI buttons and the title swap their placeholder views for `Image` views.

**Tech Stack:** Swift 5.9, SwiftUI, SpriteKit, XCTest, Xcode asset catalog.

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `FishNShips/Assets.xcassets/<name>.imageset/` | Create ×16 | Register each PNG as a named image asset |
| `FishNShips/Models/SlotSymbol.swift` | Modify | Add 4 cases, `imageName` property, updated weights |
| `FishNShipsTests/Models/SlotSymbolTests.swift` | Create | 3 unit tests for case count, weight sum, image names |
| `FishNShips/Scene/SymbolNode.swift` | Modify | Implement texture-loading path in `configure()` |
| `FishNShips/Scene/ReelNode.swift` | Modify | Default `useTexture: true`, tint during spin |
| `FishNShips/Views/SpinButtonView.swift` | Modify | Replace text buttons with sprite `Image` views |
| `FishNShips/Views/GameView.swift` | Modify | Replace `Text` title with `Image("asset_game_title")` |

---

## Task 1: Asset Catalog — Add 16 Image Sets

**Files:**
- Create: `FishNShips/Assets.xcassets/<name>.imageset/Contents.json` ×16
- Copy: `assets/sprites/<name>.png` → `FishNShips/Assets.xcassets/<name>.imageset/<name>.png`

Each image set has the same `Contents.json` structure (1× slot filled, 2× and 3× empty). The 16 sets to add:

```
asset_fish_clown, asset_fish_octopus, asset_fish_turtle, asset_fish_tang,
asset_scatter_pearl, asset_wild_sub,
asset_dwood_a, asset_dwood_k, asset_dwood_q, asset_dwood_j,
asset_dwood_ten, asset_dwood_nine,
asset_button_spin, asset_button_bet_up, asset_button_bet_down,
asset_game_title
```

- [ ] **Step 1: Create all 16 imagesets with a shell script**

Run from the repo root:

```bash
cd /Users/leolo/Desktop/code/fish-n-ships

NAMES=(
  asset_fish_clown asset_fish_octopus asset_fish_turtle asset_fish_tang
  asset_scatter_pearl asset_wild_sub
  asset_dwood_a asset_dwood_k asset_dwood_q asset_dwood_j
  asset_dwood_ten asset_dwood_nine
  asset_button_spin asset_button_bet_up asset_button_bet_down
  asset_game_title
)

for NAME in "${NAMES[@]}"; do
  DIR="FishNShips/Assets.xcassets/${NAME}.imageset"
  mkdir -p "$DIR"
  cp "assets/sprites/${NAME}.png" "$DIR/${NAME}.png"
  cat > "$DIR/Contents.json" <<ENDJSON
{
  "images" : [
    {
      "filename" : "${NAME}.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
ENDJSON
done
```

- [ ] **Step 2: Verify all 16 directories were created**

```bash
ls FishNShips/Assets.xcassets/ | grep -c "^asset_"
```

Expected output: `16`

- [ ] **Step 3: Commit**

```bash
git add FishNShips/Assets.xcassets/
git commit -m "feat(m2): add 16 sprite image sets to Assets.xcassets"
```

---

## Task 2: SlotSymbol — Add Cases, imageName, Update Weights

**Files:**
- Modify: `FishNShips/Models/SlotSymbol.swift`
- Create: `FishNShipsTests/Models/SlotSymbolTests.swift`

- [ ] **Step 1: Write the failing tests first**

Create `FishNShipsTests/Models/SlotSymbolTests.swift`:

```swift
import XCTest
@testable import FishNShips

final class SlotSymbolTests: XCTestCase {

    func test_case_count_is_12() {
        XCTAssertEqual(SlotSymbol.allCases.count, 12)
    }

    func test_weights_sum_to_100() {
        let total = SlotSymbol.allCases.reduce(0) { $0 + $1.weight }
        XCTAssertEqual(total, 100)
    }

    func test_all_cases_have_image_name() {
        for symbol in SlotSymbol.allCases {
            XCTAssertFalse(symbol.imageName.isEmpty, "\(symbol) has empty imageName")
        }
    }
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
xcodebuild -project FishNShips.xcodeproj \
  -scheme FishNShips \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  test -only-testing:FishNShipsTests/SlotSymbolTests 2>&1 | tail -20
```

Expected: compile error — `imageName` does not exist on `SlotSymbol`.

- [ ] **Step 3: Update SlotSymbol.swift**

Replace the entire file content with:

```swift
import SwiftUI

enum SlotSymbol: CaseIterable {
    // High-paying
    case clownfish, octopus, seaTurtle, blueTang
    // Low-paying
    case ace, king, queen, jack, ten, nine
    // Special
    case wild, pearl

    var imageName: String {
        switch self {
        case .clownfish:  return "asset_fish_clown"
        case .octopus:    return "asset_fish_octopus"
        case .seaTurtle:  return "asset_fish_turtle"
        case .blueTang:   return "asset_fish_tang"
        case .ace:        return "asset_dwood_a"
        case .king:       return "asset_dwood_k"
        case .queen:      return "asset_dwood_q"
        case .jack:       return "asset_dwood_j"
        case .ten:        return "asset_dwood_ten"
        case .nine:       return "asset_dwood_nine"
        case .wild:       return "asset_wild_sub"
        case .pearl:      return "asset_scatter_pearl"
        }
    }

    var placeholderColor: Color {
        switch self {
        case .clownfish:  return Color(hex: 0xE8541A)
        case .octopus:    return Color(hex: 0x7B3FB5)
        case .seaTurtle:  return Color(hex: 0x2A8A4A)
        case .blueTang:   return Color(hex: 0x1A6AB5)
        case .ace:        return Color(hex: 0xC8A020)
        case .king:       return Color(hex: 0x8A7040)
        case .queen:      return Color(hex: 0x9A6050)
        case .jack:       return Color(hex: 0x6A5030)
        case .ten:        return Color(hex: 0x5A6040)
        case .nine:       return Color(hex: 0x4A5060)
        case .wild:       return Color(hex: 0x2ACFCF)
        case .pearl:      return Color(hex: 0xD0D0FF)
        }
    }

    var placeholderUIColor: UIColor { UIColor(placeholderColor) }

    /// Relative weight for spin randomisation. Total = 100.
    var weight: Int {
        switch self {
        case .clownfish:  return 14
        case .octopus:    return 11
        case .seaTurtle:  return 11
        case .blueTang:   return 11
        case .ace:        return 9
        case .king:       return 9
        case .queen:      return 8
        case .jack:       return 8
        case .ten:        return 8
        case .nine:       return 8
        case .wild:       return 2
        case .pearl:      return 1
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

- [ ] **Step 4: Run SlotSymbolTests — expect all 3 to pass**

```bash
xcodebuild -project FishNShips.xcodeproj \
  -scheme FishNShips \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  test -only-testing:FishNShipsTests/SlotSymbolTests 2>&1 | grep -E "(PASS|FAIL|error:)"
```

Expected:
```
Test Case '-[FishNShipsTests.SlotSymbolTests test_case_count_is_12]' passed
Test Case '-[FishNShipsTests.SlotSymbolTests test_weights_sum_to_100]' passed
Test Case '-[FishNShipsTests.SlotSymbolTests test_all_cases_have_image_name]' passed
```

- [ ] **Step 5: Run all existing tests — expect all to still pass**

```bash
xcodebuild -project FishNShips.xcodeproj \
  -scheme FishNShips \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  test 2>&1 | grep -E "(passed|failed|error:)" | tail -10
```

Expected: no failures.

- [ ] **Step 6: Commit**

```bash
git add FishNShips/Models/SlotSymbol.swift FishNShipsTests/Models/SlotSymbolTests.swift
git commit -m "feat(m2): expand SlotSymbol to 12 cases with imageName and updated weights"
```

---

## Task 3: SymbolNode — Implement Texture Loading

**Files:**
- Modify: `FishNShips/Scene/SymbolNode.swift`

- [ ] **Step 1: Replace the useTexture stub with real implementation**

Replace the full content of `FishNShips/Scene/SymbolNode.swift`:

```swift
import SpriteKit

/// A single grid cell. M1: coloured square. M2+: named texture from Assets.xcassets.
final class SymbolNode: SKSpriteNode {

    static let cellSize = CGSize(width: 64, height: 64)

    private(set) var symbol: SlotSymbol

    init(symbol: SlotSymbol) {
        self.symbol = symbol
        super.init(texture: nil, color: symbol.placeholderUIColor, size: SymbolNode.cellSize)
        configure(symbol: symbol)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("not used") }

    /// Call to update this node's symbol.
    /// - Parameters:
    ///   - symbol: The new symbol to display.
    ///   - useTexture: true (M2+) = named texture. false = solid colour placeholder.
    func configure(symbol: SlotSymbol, useTexture: Bool = true) {
        self.symbol = symbol
        if useTexture {
            texture = SKTexture(imageNamed: symbol.imageName)
            colorBlendFactor = 0
            size = SymbolNode.cellSize
        } else {
            texture = nil
            color = symbol.placeholderUIColor
            colorBlendFactor = 1.0
        }
    }
}
```

- [ ] **Step 2: Build to verify no compile errors**

```bash
xcodebuild -project FishNShips.xcodeproj \
  -scheme FishNShips \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add FishNShips/Scene/SymbolNode.swift
git commit -m "feat(m2): implement texture loading in SymbolNode"
```

---

## Task 4: ReelNode — Default to Textures, Tint During Spin

**Files:**
- Modify: `FishNShips/Scene/ReelNode.swift`

The two changes:
1. `updateSymbols(_:useTexture:)` default changes from `false` to `true`
2. The spin colour-cycle now sets `colorBlendFactor = 1.0` to tint the texture with a cycling colour. The snap phase calls `updateSymbols(finalSymbols)` (no arg needed — default is now `true`), which sets `colorBlendFactor = 0` and restores the real sprite.

- [ ] **Step 1: Update ReelNode.swift**

Replace the full content of `FishNShips/Scene/ReelNode.swift`:

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

    func updateSymbols(_ symbols: [SlotSymbol], useTexture: Bool = true) {
        for (i, sym) in symbols.prefix(3).enumerated() {
            symbolNodes[i].configure(symbol: sym, useTexture: useTexture)
        }
    }

    // MARK: - Spin Animation

    /// Plays the spin animation for this reel.
    /// - Parameters:
    ///   - finalSymbols: The 3 symbols to snap to at the end (top→bottom).
    ///   - delay: Stagger delay before this reel starts (col * 0.15 s).
    ///   - completion: Called when the animation finishes.
    func spinAnimation(finalSymbols: [SlotSymbol], delay: TimeInterval, completion: @escaping () -> Void) {
        let cycleColors = SlotSymbol.allCases.map { $0.placeholderUIColor }
        var colorIndex = 0
        let cycleKey = "spin-cycle-\(column)"

        // Main sequence — cycle is run separately so it can be stopped independently
        let sequence = SKAction.sequence([
            // Wait for stagger
            SKAction.wait(forDuration: delay),
            // Start color-cycling on a separate action key
            SKAction.run { [weak self] in
                guard let self else { return }
                let cycle = SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.run { [weak self] in
                            colorIndex = (colorIndex + 1) % cycleColors.count
                            self?.symbolNodes.forEach {
                                $0.color = cycleColors[colorIndex]
                                $0.colorBlendFactor = 1.0
                            }
                        },
                        SKAction.wait(forDuration: 0.06)
                    ])
                )
                self.run(cycle, withKey: cycleKey)
            },
            // Fast cycling phase (0.9 s)
            SKAction.wait(forDuration: 0.9),
            // Stop cycle and snap to final symbols (useTexture: true reveals sprites)
            SKAction.run { [weak self] in
                self?.removeAction(forKey: cycleKey)
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

- [ ] **Step 2: Build and run all tests**

```bash
xcodebuild -project FishNShips.xcodeproj \
  -scheme FishNShips \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  test 2>&1 | grep -E "(passed|failed|error:)" | tail -10
```

Expected: no failures.

- [ ] **Step 3: Commit**

```bash
git add FishNShips/Scene/ReelNode.swift
git commit -m "feat(m2): default ReelNode to useTexture:true, tint sprites during spin"
```

---

## Task 5: SpinButtonView — Sprite Image Buttons

**Files:**
- Modify: `FishNShips/Views/SpinButtonView.swift`

Replace the `Text` + `RoundedRectangle` background buttons with `Image` views. The `Button` tap target and disabled state logic remain unchanged.

- [ ] **Step 1: Replace SpinButtonView.swift**

```swift
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
```

- [ ] **Step 2: Build to verify no compile errors**

```bash
xcodebuild -project FishNShips.xcodeproj \
  -scheme FishNShips \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add FishNShips/Views/SpinButtonView.swift
git commit -m "feat(m2): replace button text/rect with sprite images in SpinButtonView"
```

---

## Task 6: GameView — Sprite Title

**Files:**
- Modify: `FishNShips/Views/GameView.swift`

Replace the `Text("FISH N' SHIPS")` title bar with the `asset_game_title` image.

- [ ] **Step 1: Update the title bar in GameView.swift**

In `FishNShips/Views/GameView.swift`, replace:

```swift
                // Title bar
                Text("FISH N' SHIPS")
                    .font(.title2.bold())
                    .foregroundStyle(.yellow)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: 0x0D1F3A))
```

with:

```swift
                // Title bar
                Image("asset_game_title")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 60)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: 0x0D1F3A))
```

- [ ] **Step 2: Build to verify no compile errors**

```bash
xcodebuild -project FishNShips.xcodeproj \
  -scheme FishNShips \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add FishNShips/Views/GameView.swift
git commit -m "feat(m2): replace text title with asset_game_title sprite in GameView"
```

---

## Task 7: Final Verification

- [ ] **Step 1: Run full test suite**

```bash
xcodebuild -project FishNShips.xcodeproj \
  -scheme FishNShips \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  test 2>&1 | grep -E "Test Suite|passed|failed" | tail -10
```

Expected: 23 tests pass (20 existing + 3 new SlotSymbolTests), 0 failures.

- [ ] **Step 2: Verify xcassets count**

```bash
ls FishNShips/Assets.xcassets/ | grep "^asset_" | wc -l
```

Expected: `16`

- [ ] **Step 3: Launch in simulator and verify visually**

Open the simulator, build and run. Check:
- 5×3 grid shows pixel-art sprites after spin settles (no coloured squares)
- Colour-cycle flash plays during spin, sprites revealed on snap
- SPIN, BET+, BET− buttons show sprite artwork
- Title bar shows the game title sprite
- No crashes on rapid SPIN taps

- [ ] **Step 4: Merge to master and tag**

```bash
git checkout master
git merge --no-ff feat/milestone2-sprite-assets -m "feat: Milestone 2 — sprite assets complete"
git tag 0.2.0
git push origin master --tags
```

---

## Acceptance Criteria Checklist

- [ ] All 16 image sets present in `Assets.xcassets` and build without errors
- [ ] 5×3 grid displays pixel-art sprites (no coloured squares) after spin settles
- [ ] Colour-cycle flash plays correctly during spin, sprites revealed on snap
- [ ] SPIN, BET+, BET− buttons show pixel-art sprite artwork
- [ ] Title bar shows `asset_game_title` sprite instead of plain text
- [ ] `SlotSymbolTests` — all 3 tests pass
- [ ] All 23 tests pass (20 existing + 3 new)
- [ ] No crashes on rapid SPIN taps
