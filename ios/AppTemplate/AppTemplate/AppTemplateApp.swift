import SwiftUI
import SwiftData

@main
struct AppTemplateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var router = AppRouter.shared
    @StateObject private var theme  = AppTheme.shared

    @Environment(\.scenePhase) private var scenePhase
    @State private var didPrepareUITestState = false

    init() {
        AppEnvironment.load()
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
                .task {
                    await prepareUITestStateIfNeeded()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                SyncManager.shared.pullIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        if isUITestingHomeMode {
            TasksTabView()
        } else {
            switch router.root {
            case .splash:      SplashView()
            case .login:       LoginView()
            case .onboarding:  OnboardingView()
            case .paywall:     PaywallFlowView()
            case .home:        TasksTabView()
            }
        }
    }

    private var launchArguments: [String] {
        ProcessInfo.processInfo.arguments
    }

    private var isUITesting: Bool {
        launchArguments.contains("-ui-testing")
    }

    private var isUITestingHomeMode: Bool {
        launchArguments.contains("-ui-testing-home")
    }

    private var shouldResetUITestData: Bool {
        launchArguments.contains("-ui-testing-reset-data")
    }

    @MainActor
    private func prepareUITestStateIfNeeded() async {
        guard isUITesting, !didPrepareUITestState else { return }
        didPrepareUITestState = true

        if shouldResetUITestData {
            let context = LocalDatabase.shared.context
            let descriptor = FetchDescriptor<TaskItem>()
            if let existingTasks = try? context.fetch(descriptor) {
                existingTasks.forEach { context.delete($0) }
                try? context.save()
            }

            UserDefaults.standard.removeObject(forKey: "didCompleteOnboarding")
        }

        if isUITestingHomeMode {
            router.root = .home
        }
    }
}
