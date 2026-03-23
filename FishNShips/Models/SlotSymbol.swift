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
