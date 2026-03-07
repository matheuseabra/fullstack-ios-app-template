import Foundation
import RevenueCat

// MARK: - PaywallViewModel
// Drives the custom pricing plans screen (Screen 2). Loads offerings
// from RevenueCat, manages plan selection, and handles purchase / restore.

@MainActor
final class PaywallViewModel: ObservableObject {

    // MARK: - Plan Selection

    enum Plan: String {
        case yearly, monthly
    }

    @Published var selectedPlan: Plan = .yearly
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Packages (populated from RevenueCat offerings)

    @Published private(set) var packages: [Package] = []

    var yearlyPackage: Package? {
        packages.first { $0.storeProduct.productIdentifier == PaymentManager.ProductID.yearly }
    }

    var monthlyPackage: Package? {
        packages.first { $0.storeProduct.productIdentifier == PaymentManager.ProductID.monthly }
    }

    private var selectedPackage: Package? {
        switch selectedPlan {
        case .yearly:  return yearlyPackage
        case .monthly: return monthlyPackage
        }
    }

    // MARK: - Load Offerings

    func loadOfferings() async {
        await PaymentManager.shared.loadOfferings()
        packages = PaymentManager.shared.currentPackages
    }

    // MARK: - Purchase

    func purchase() async -> Bool {
        guard let package = selectedPackage else {
            errorMessage = "Please select a plan."
            showError = true
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await PaymentManager.shared.purchase(package: package)
            if PaymentManager.shared.hasProAccess {
                HapticManager.success()
                return true
            }
        } catch PaymentError.userCancelled {
            // User tapped cancel — do nothing
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.error()
        }

        return false
    }

    // MARK: - Restore

    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await PaymentManager.shared.restorePurchases()
            if PaymentManager.shared.hasProAccess {
                HapticManager.success()
                return true
            } else {
                errorMessage = "No prior purchases found."
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.error()
        }

        return false
    }
}
