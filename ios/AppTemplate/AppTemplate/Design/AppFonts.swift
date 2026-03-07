import SwiftUI

// MARK: - Font Helpers
// Uses system fonts (San Francisco). Replace with custom font names if needed.

extension Font {
    /// Large headings and hero text
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Body copy and UI labels
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Code blocks and numeric data
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
