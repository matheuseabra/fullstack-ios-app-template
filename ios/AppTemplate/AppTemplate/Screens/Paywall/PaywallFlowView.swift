import SwiftUI

// MARK: - PaywallFlowView
// The current Stitch implementation uses a single paywall screen.

struct PaywallFlowView: View {
    let onDismiss: (() -> Void)?

    init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    var body: some View {
        PaywallView(onDismiss: onDismiss)
    }
}
