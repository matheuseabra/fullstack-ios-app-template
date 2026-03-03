import Foundation
import RevenueCat

// MARK: - PaywallViewModel
// RevenueCat's native PaywallView manages its own state (offerings, loading,
// purchase flow). This view model is retained only for any auxiliary logic
// that lives outside the RC-rendered paywall (e.g. trial explainer screen).

@MainActor
final class PaywallViewModel: ObservableObject {

    // MARK: - Restore (used by manual "Restore" buttons outside RC's PaywallView)

    @Published var isLoading = false
    @Published var errorMessage: String?

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await PaymentManager.shared.restorePurchases()
            if PaymentManager.shared.hasProAccess {
                HapticManager.success()
                AppRouter.shared.advanceToHome()
            } else {
                errorMessage = "No prior purchases found."
            }
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.error()
        }
    }
}
