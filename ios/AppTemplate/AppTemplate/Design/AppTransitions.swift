import SwiftUI

// MARK: - Named Transitions

extension AnyTransition {
    /// Slides content up from the bottom
    static var slideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }

    /// Standard push-style lateral slide (left → right)
    static var slidePush: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
    }

    /// Fade in + slight scale-up (modal feel)
    static var fadeScale: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.96)),
            removal: .opacity.combined(with: .scale(scale: 1.04))
        )
    }
}

// MARK: - Named Animations

extension Animation {
    static var spring: Animation {
        .spring(response: 0.4, dampingFraction: 0.75)
    }

    static var snappy: Animation {
        .spring(response: 0.25, dampingFraction: 0.85)
    }
}
