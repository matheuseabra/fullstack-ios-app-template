import SwiftUI
import SwiftData

@main
struct AppTemplateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var router = AppRouter.shared
    @StateObject private var theme  = AppTheme.shared

    @Environment(\.scenePhase) private var scenePhase

    init() {
        AppEnvironment.load()

        if AppEnvironment.enablePaywall {
            PaymentManager.configure(apiKey: AppEnvironment.revenueCatKey)
        }
        if AppEnvironment.enableAnalytics {
            Analytics.configure(apiKey: AppEnvironment.postHogKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .preferredColorScheme(theme.colorScheme)
                .environmentObject(router)
                .environmentObject(theme)
                .modelContainer(LocalDatabase.shared.container)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, AppEnvironment.enableAuth {
                SyncManager.shared.pullIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        switch router.root {
        case .splash:      SplashView()
        case .login:       LoginView()
        case .onboarding:  OnboardingView()
        case .paywall:     PaywallFlowView()
        case .home:        TasksTabView()
        }
    }
}
