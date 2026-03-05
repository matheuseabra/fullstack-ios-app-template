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
            // Gate 1: Auth
            let isAuthenticated = AppEnvironment.enableAuth
                ? AuthManager.shared.isAuthenticated
                : true  // skip auth → treat as authenticated

            guard isAuthenticated else {
                root = .login
                return
            }

            // Gate 2: Onboarding
            let didCompleteOnboarding = AppEnvironment.enableOnboarding
                ? UserDefaults.standard.bool(forKey: "didCompleteOnboarding")
                : true  // skip onboarding → treat as completed

            guard didCompleteOnboarding else {
                root = .onboarding
                return
            }

            // Gate 3: Paywall
            let hasActiveSubscription = AppEnvironment.enablePaywall
                ? await checkSubscription()
                : true  // skip paywall → treat as subscribed

            guard hasActiveSubscription else {
                root = .paywall
                return
            }

            root = .home
        }
    }

    func advanceToHome() {
        root = .home
    }

    func advanceToPaywall() {
        root = .paywall
    }

    func signOut() {
        if AppEnvironment.enableAuth {
            AuthManager.shared.signOut()
        }
        path = NavigationPath()
        root = AppEnvironment.enableAuth ? .login : .home
    }

    // MARK: - Private

    private func checkSubscription() async -> Bool {
        // Refresh CustomerInfo from RevenueCat cache (fast, no network unless stale).
        await PaymentManager.shared.refreshCustomerInfo()
        return PaymentManager.shared.hasProAccess
    }
}
