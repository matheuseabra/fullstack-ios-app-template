import SwiftUI
import SwiftData

@main
struct AppTemplateApp: App {
    @StateObject private var router = AppRouter.shared
    @StateObject private var theme  = AppTheme.shared

    init() {
        // Configure third-party SDKs
        PaymentManager.configure(apiKey: AppEnvironment.revenueCatKey)
        Analytics.configure(apiKey: AppEnvironment.postHogKey)
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .preferredColorScheme(theme.colorScheme)
                .environmentObject(router)
                .environmentObject(theme)
                .modelContainer(LocalDatabase.shared.container)
        }
    }

    @ViewBuilder
    private var rootView: some View {
        switch router.root {
        case .splash:      SplashView()
        case .login:       LoginView()
        case .onboarding:  OnboardingView()
        case .paywall:     PaywallFlowView()
        case .home:        HomeView()
        }
    }
}
