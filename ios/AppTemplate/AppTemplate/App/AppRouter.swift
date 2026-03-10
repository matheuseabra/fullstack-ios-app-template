import SwiftUI

// MARK: - AppRouter
// Central navigation state machine. Owns the root destination
// and all modal navigation paths.

@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    @Published var root: RootDestination = .splash
    @Published var path = NavigationPath()

    enum RootDestination {
        case splash
        case login
        case onboarding
        case paywall
        case home
    }

    // MARK: - Advance Logic
    // Called by SplashView after 2s delay, or after any auth state change.

    func advance() {
        Task {
            if AuthManager.shared.isAuthenticated {
                // TODO: Check if onboarding is complete (persist flag with @AppStorage)
                let didCompleteOnboarding = UserDefaults.standard.bool(forKey: "didCompleteOnboarding")
                let hasActiveSubscription = await checkSubscription()

                if !didCompleteOnboarding {
                    root = .onboarding
                } else if !hasActiveSubscription {
                    root = .paywall
                } else {
                    root = .home
                }
            } else {
                root = .login
            }
        }
    }

    func advanceToHome() {
        // Only allow navigation to home if user has Pro (enforce hard paywall)
        if PaymentManager.shared.hasProAccess {
            root = .home
        }
    }

    func advanceToPaywall() {
        root = .paywall
    }

    func signOut() {
        AuthManager.shared.signOut()
        path = NavigationPath()
        root = .login
    }

    // MARK: - Private

    private func checkSubscription() async -> Bool {
        // Refresh CustomerInfo from RevenueCat cache (fast, no network unless stale).
        await PaymentManager.shared.refreshCustomerInfo()
        return PaymentManager.shared.hasProAccess
    }
}
