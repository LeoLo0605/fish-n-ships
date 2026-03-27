# Fish N' Ships — Milestone 2 Design Spec
**Date:** 2026-03-28
**Scope:** Replace all placeholder coloured squares, buttons, and title with pixel-art sprite assets from the pre-cropped spritesheet PNGs.

---

## 1. Overview

Milestone 2 upgrades the visual layer of Fish N' Ships from solid-colour placeholders to real pixel-art sprites. No game logic changes. The ViewModel, grid, win detection, and animation timing are all untouched. The upgrade surface is: asset catalog, symbol enum, SymbolNode texture loading, and SwiftUI button/title views.

**Tech stack:** unchanged — Swift 5.9, SwiftUI, SpriteKit, iOS 17+.

---

## 2. Symbol Set Expansion

Four new low-paying symbols are added to bring the total to 12.

| Symbol | Case | Image asset | Weight |
|---|---|---|---|
| Clownfish | `clownfish` | `asset_fish_clown` | 14 |
| Octopus | `octopus` | `asset_fish_octopus` | 11 |
| Sea Turtle | `seaTurtle` | `asset_fish_turtle` | 11 |
| Blue Tang | `blueTang` | `asset_fish_tang` | 11 |
| Ace | `ace` | `asset_dwood_a` | 9 |
| King | `king` | `asset_dwood_k` | 9 |
| Queen *(new)* | `queen` | `asset_dwood_q` | 8 |
| Jack *(new)* | `jack` | `asset_dwood_j` | 8 |
| Ten *(new)* | `ten` | `asset_dwood_ten` | 8 |
| Nine *(new)* | `nine` | `asset_dwood_nine` | 8 |
| Wild | `wild` | `asset_wild_sub` | 2 |
| Pearl | `pearl` | `asset_scatter_pearl` | 1 |
| **Total** | | | **100** |

---

## 3. Asset Catalog

All pre-cropped PNGs live in `assets/sprites/`. Each is added to `FishNShips/Assets.xcassets` as its own image set at the 1× slot (single resolution). The `GameSpriteSheet` image set is retained but no longer referenced in code.

**16 new image sets:**

| Image set name | File |
|---|---|
| `asset_fish_clown` | `asset_fish_clown.png` |
| `asset_fish_octopus` | `asset_fish_octopus.png` |
| `asset_fish_turtle` | `asset_fish_turtle.png` |
| `asset_fish_tang` | `asset_fish_tang.png` |
| `asset_scatter_pearl` | `asset_scatter_pearl.png` |
| `asset_wild_sub` | `asset_wild_sub.png` |
| `asset_dwood_a` | `asset_dwood_a.png` |
| `asset_dwood_k` | `asset_dwood_k.png` |
| `asset_dwood_q` | `asset_dwood_q.png` |
| `asset_dwood_j` | `asset_dwood_j.png` |
| `asset_dwood_ten` | `asset_dwood_ten.png` |
| `asset_dwood_nine` | `asset_dwood_nine.png` |
| `asset_button_spin` | `asset_button_spin.png` |
| `asset_button_bet_up` | `asset_button_bet_up.png` |
| `asset_button_bet_down` | `asset_button_bet_down.png` |
| `asset_game_title` | `asset_game_title.png` |

---

## 4. Code Changes

### 4.1 `SlotSymbol.swift`

- Add 4 new cases: `queen`, `jack`, `ten`, `nine`
- Add `imageName: String` computed property mapping each case to its asset catalog name
- Update all weights to the values in section 2 (total = 100)
- `placeholderColor` and `placeholderUIColor` are retained for any future fallback use

### 4.2 `SymbolNode.swift`

- Change `configure(symbol:useTexture:)` default parameter to `useTexture: true`
- `useTexture: true` path:
  - `texture = SKTexture(imageNamed: symbol.imageName)`
  - `colorBlendFactor = 0`
  - `size = SymbolNode.cellSize` — explicitly set to 64×64 pt so the node does not resize to the texture's native resolution
- `useTexture: false` path: unchanged (placeholder colours, kept for reference)

### 4.3 `ReelNode.swift`

- `updateSymbols(_:useTexture:)` default parameter changes to `useTexture: true`
- Spin animation colour-cycle phase: `colorBlendFactor = 1.0` tints the texture with the cycling colour — same visual flash effect on top of real sprites
- Snap phase calls `updateSymbols(finalSymbols)` with `useTexture: true`, which sets `colorBlendFactor = 0` to reveal the actual sprite

### 4.4 `SpinButtonView.swift`

Replace rounded-rectangle button backgrounds with sprite images:

- **SPIN** → `Image("asset_button_spin").resizable().aspectRatio(contentMode: .fit)`, 50% opacity when `!canSpin`
- **BET+** → `Image("asset_button_bet_up").resizable().aspectRatio(contentMode: .fit)`
- **BET−** → `Image("asset_button_bet_down").resizable().aspectRatio(contentMode: .fit)`

SwiftUI `Button` tap targets and disabled state logic are unchanged.

### 4.5 `GameView.swift`

Replace the `Text("FISH N' SHIPS")` title with:
```swift
Image("asset_game_title")
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(height: 60)
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity)
    .background(Color(hex: 0x0D1F3A))
```

---

## 5. Tests

### Existing tests — no changes required
- `ReelGridTests` — grid structure unaffected
- `GameViewModelTests` — ViewModel logic unaffected

### New: `FishNShipsTests/Models/SlotSymbolTests.swift`

| Test | Assertion |
|---|---|
| `test_case_count_is_12` | `SlotSymbol.allCases.count == 12` |
| `test_weights_sum_to_100` | Sum of all weights == 100 |
| `test_all_cases_have_image_name` | No `imageName` is empty string |

---

## 6. What Milestone 2 Does NOT Include

- Win detection or pay table
- Pearl scatter / frame / build mechanic
- Bonus game ("Kraken's Awakening") — `asset_bonus_chest.png` and `asset_kraken_awakens.png` remain in `assets/sprites/` but are NOT added to xcassets in M2
- Pearl light variant — `asset_scatter_pearl_light.png` remains in `assets/sprites/` but is NOT added to xcassets in M2 (reserved for win-state animation)
- Scroll-style reel animation (colour-cycle snap is retained)
- Sound effects or music
- Data persistence

---

## 7. Acceptance Criteria

- [ ] All 16 image sets present in `Assets.xcassets` and build without errors
- [ ] 5×3 grid displays pixel-art sprites (no coloured squares) after spin settles
- [ ] Colour-cycle flash plays correctly during spin, sprites revealed on snap
- [ ] SPIN, BET+, BET− buttons show pixel-art sprite artwork
- [ ] Title bar shows `asset_game_title` sprite instead of plain text
- [ ] `SlotSymbolTests` — all 3 tests pass
- [ ] All 20 existing tests continue to pass
- [ ] No crashes on rapid SPIN taps
