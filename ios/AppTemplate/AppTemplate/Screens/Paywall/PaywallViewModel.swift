import Foundation

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var selectedPlan: Plan = .yearly
    @Published var isLoading = false
    @Published var errorMessage: String?

    enum Plan: String, CaseIterable, Identifiable {
        case yearly  = "annual"
        case monthly = "monthly"
        var id: String { rawValue }
    }

    func purchase() async {
        isLoading = true
        errorMessage = nil
        HapticManager.medium()

        // With RevenueCat installed, use PaymentManager.
        // For now, simulate success after a short delay.
        do {
            try await Task.sleep(for: .seconds(1))
            // TODO: try await PaymentManager.shared.purchase(package: matchedPackage)
            Analytics.track(.subscriptionPurchased(plan: selectedPlan.rawValue, price: 0))
            HapticManager.success()
            AppRouter.shared.advanceToHome()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.error()
        }
        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true
        do {
            try await PaymentManager.shared.restorePurchases()
            AppRouter.shared.advanceToHome()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func selectPlan(_ plan: Plan) {
        HapticManager.selection()
        Analytics.track(.planSelected(plan: plan.rawValue))
        selectedPlan = plan
    }
}
