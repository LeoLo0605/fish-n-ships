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
