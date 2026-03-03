import Foundation

// MARK: - PaymentManager
// Wraps RevenueCat for subscription management.
// Add purchases-ios via Xcode → File → Add Package Dependencies,
// then remove the #if canImport guard.

#if canImport(RevenueCat)
import RevenueCat

@MainActor
final class PaymentManager: ObservableObject {
    static let shared = PaymentManager()

    @Published private(set) var offerings: Offerings?
    @Published fileprivate(set) var customerInfo: CustomerInfo?

    enum Plan: String { case monthly = "monthly", yearly = "annual" }

    // MARK: - Setup

    /// Call on app launch before any purchase UI is shown.
    static func configure(apiKey: String) {
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = PaymentManagerDelegate.shared
    }

    // MARK: - State

    func refreshCustomerInfo() async {
        customerInfo = try? await Purchases.shared.customerInfo()
    }

    func loadOfferings() async {
        offerings = try? await Purchases.shared.offerings()
    }

    var isSubscribed: Bool {
        customerInfo?.entitlements.active.isEmpty == false
    }

    // MARK: - Purchase

    func purchase(package: Package) async throws {
        let result = try await Purchases.shared.purchase(package: package)
        customerInfo = result.customerInfo
        if !result.userCancelled {
            Analytics.track(.subscriptionPurchased(
                plan: package.identifier,
                price: NSDecimalNumber(decimal: package.storeProduct.price).doubleValue
            ))
        }
    }

    func restorePurchases() async throws {
        customerInfo = try await Purchases.shared.restorePurchases()
    }
}

// MARK: - Delegate

private final class PaymentManagerDelegate: NSObject, PurchasesDelegate {
    static let shared = PaymentManagerDelegate()
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in PaymentManager.shared.customerInfo = customerInfo }
    }
}

#else
// MARK: - Stub (compiles without RevenueCat package)

@MainActor
final class PaymentManager: ObservableObject {
    static let shared = PaymentManager()

    var isSubscribed: Bool { false }

    static func configure(apiKey: String) {
        // TODO: Install purchases-ios via SPM
    }

    func refreshCustomerInfo() async {}
    func loadOfferings() async {}
    func restorePurchases() async throws {}

    enum Plan: String { case monthly, yearly }
}
#endif
