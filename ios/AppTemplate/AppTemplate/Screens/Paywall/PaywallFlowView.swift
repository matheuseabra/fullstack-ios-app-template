import SwiftUI

// MARK: - PaywallFlowView
// Wraps the two-screen paywall flow in a NavigationStack:
// Screen 1: TrialExplainerView → Screen 2: PaywallView

struct PaywallFlowView: View {
    var body: some View {
        NavigationStack {
            TrialExplainerView()
        }
    }
}
