import Foundation
import RevenueCat

// MARK: - Constants

extension PaymentManager {
    /// The entitlement identifier configured in RevenueCat dashboard.
    static let entitlementID = "GhostCrew Pro"

    /// Product identifiers matching your App Store Connect / RevenueCat products.
    enum ProductID {
        static let monthly  = "monthly"
        static let yearly   = "yearly"
        static let lifetime = "lifetime"
    }
}

// MARK: - PaymentManager

@MainActor
final class PaymentManager: ObservableObject {
    static let shared = PaymentManager()

    // MARK: Published State

    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var offerings: Offerings?
    @Published private(set) var isLoading = false

    // MARK: Computed

    /// True when the user has an active "GhostCrew Pro" entitlement.
    var hasProAccess: Bool {
        customerInfo?.entitlements[Self.entitlementID]?.isActive == true
    }

    /// The current offering from the dashboard (nil until loadOfferings() completes).
    var currentOffering: Offering? { offerings?.current }

    /// Convenience: packages in the current offering, ordered.
    var currentPackages: [Package] { currentOffering?.availablePackages ?? [] }

    // MARK: - Setup

    /// Call once on app launch, before any purchase UI is shown.
    static func configure(apiKey: String) {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: apiKey)
                .with(usesStoreKit2IfAvailable: true)
                .build()
        )
        Purchases.shared.delegate = PaymentManagerDelegate.shared
    }

    // MARK: - User Identity

    /// Sync with your Supabase user ID so purchase history follows the user
    /// across installs / devices. Call after a successful sign-in.
    func logIn(userId: String) async throws {
        let (info, _) = try await Purchases.shared.logIn(userId)
        customerInfo = info
    }

    /// Reset to an anonymous identity. Call on sign-out.
    func logOut() async throws {
        customerInfo = try await Purchases.shared.logOut()
    }

    // MARK: - State Refresh

    func refreshCustomerInfo() async {
        customerInfo = try? await Purchases.shared.customerInfo()
    }

    func loadOfferings() async {
        isLoading = true
        defer { isLoading = false }
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            // Non-fatal: paywall simply won't show store prices.
            print("[PaymentManager] loadOfferings failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase

    /// Purchase a `Package` from the current offering.
    /// Throws `PaymentError.userCancelled` when the user dismisses the sheet.
    func purchase(package: Package) async throws {
        isLoading = true
        defer { isLoading = false }

        let result = try await Purchases.shared.purchase(package: package)

        if result.userCancelled {
            throw PaymentError.userCancelled
        }

        customerInfo = result.customerInfo

        Analytics.track(.subscriptionPurchased(
            plan: package.storeProduct.productIdentifier,
            price: NSDecimalNumber(decimal: package.storeProduct.price).doubleValue
        ))
    }

    /// Restore prior purchases (required by App Store guidelines).
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        customerInfo = try await Purchases.shared.restorePurchases()
    }

    // MARK: - Package Helpers

    /// Returns the package matching a given product identifier.
    func package(for productID: String) -> Package? {
        currentPackages.first { $0.storeProduct.productIdentifier == productID }
    }
}

// MARK: - Errors

enum PaymentError: LocalizedError {
    case userCancelled
    case noActiveSubscription
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .userCancelled:         return nil // silent — don't show UI
        case .noActiveSubscription:  return "No active subscription found."
        case .unknown(let e):        return e.localizedDescription
        }
    }
}

// MARK: - Delegate (receives real-time updates)

private final class PaymentManagerDelegate: NSObject, PurchasesDelegate {
    static let shared = PaymentManagerDelegate()

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            PaymentManager.shared.customerInfo = customerInfo
        }
    }
}
