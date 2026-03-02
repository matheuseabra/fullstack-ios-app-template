# iOS App — Setup & Architecture

> SwiftUI, local-first, minimal dependencies, production-ready patterns.

---

## Prerequisites

- Xcode 16+
- iOS 17+ deployment target
- Apple Developer account (for push notifications + StoreKit sandbox)

---

## Folder Structure

```
ios/
├── App/
│   ├── MyApp.swift                  # @main entry, env setup
│   ├── AppRouter.swift              # Central navigation + deep links
│   └── AppEnvironment.swift         # Shared env objects injected at root
│
├── Core/
│   ├── Network/
│   │   ├── APIClient.swift          # Async/await HTTP client
│   │   ├── APIEndpoints.swift       # All endpoint definitions
│   │   └── APIError.swift
│   ├── Auth/
│   │   ├── AuthManager.swift        # Supabase auth + session
│   │   ├── GoogleSignInManager.swift
│   │   └── AppleSignInManager.swift
│   ├── Storage/
│   │   ├── LocalDatabase.swift      # SwiftData / SQLite local store
│   │   └── SyncManager.swift        # Background sync coordinator
│   ├── Analytics/
│   │   └── Analytics.swift          # PostHog wrapper (typed events)
│   ├── Payments/
│   │   └── PaymentManager.swift     # RevenueCat wrapper
│   ├── Notifications/
│   │   └── NotificationManager.swift
│   └── Haptics/
│       └── HapticManager.swift
│
├── Design/
│   ├── AppColors.swift
│   ├── AppFonts.swift
│   ├── AppSpacing.swift
│   ├── AppTheme.swift
│   └── AppTransitions.swift
│
├── Components/
│   ├── AppButton.swift
│   ├── AppTextField.swift
│   ├── SkeletonView.swift
│   ├── EmptyStateView.swift
│   ├── AppDrawer.swift
│   └── FeatherIcon.swift            # Icon helper
│
├── Screens/
│   ├── Splash/
│   │   └── SplashView.swift
│   ├── Auth/
│   │   └── LoginView.swift
│   ├── Onboarding/
│   │   ├── OnboardingView.swift     # Container + step router
│   │   ├── OnboardingQuizStep.swift
│   │   └── OnboardingViewModel.swift
│   ├── Paywall/
│   │   ├── TrialExplainerView.swift # Screen 1
│   │   ├── PaywallView.swift        # Screen 2 — plans
│   │   └── PaywallViewModel.swift
│   ├── Home/                        # Core feature — replace per app
│   │   ├── HomeView.swift
│   │   └── HomeViewModel.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── SettingsViewModel.swift
│
├── Models/
│   ├── User.swift
│   ├── Subscription.swift
│   ├── OnboardingResponse.swift
│   └── [AppSpecificModels].swift
│
└── Resources/
    ├── Assets.xcassets/
    │   ├── AppIcon.appiconset/
    │   ├── Colors/                  # All named colors (dark + light variants)
    │   └── Illustrations/           # Empty state SVGs/PNGs
    ├── Fonts/                       # (empty — using system fonts)
    └── Info.plist
```

---

## Swift Packages (SPM)

Add via Xcode → File → Add Package Dependencies

```swift
// Package.swift dependencies
.package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
.package(url: "https://github.com/RevenueCat/purchases-ios", from: "4.0.0"),
.package(url: "https://github.com/PostHog/posthog-ios", from: "3.0.0"),
.package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
.package(url: "https://github.com/feathericons/feather-swift", from: "1.0.0"),
```

---

## Screens Spec

### SplashView
- Duration: 2 seconds, then auto-advance
- Logo centered (SF Symbol or custom asset)
- App name below in `display(28)`
- Background: `bg` color
- Transition: fade out → fade in to Login or Home (if already authed)

```swift
struct SplashView: View {
  var body: some View {
    ZStack {
      Color.bg.ignoresSafeArea()
      VStack(spacing: Spacing.md) {
        Image("AppLogo")
          .resizable().scaledToFit().frame(width: 80)
        Text("AppName")
          .font(.display(28))
          .foregroundColor(.textPrimary)
      }
    }
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        AppRouter.shared.advance()
      }
    }
  }
}
```

---

### LoginView
- Clean, centered layout
- Logo small at top
- "Sign in with Apple" button (black, official HIG style)
- "Sign in with Google" button (white/outlined)
- Footer: privacy policy + terms links
- No email/password (reduces friction — social only)

```swift
struct LoginView: View {
  @StateObject private var vm = LoginViewModel()

  var body: some View {
    ZStack {
      Color.bg.ignoresSafeArea()
      VStack(spacing: Spacing.xl) {
        Spacer()

        // Logo + tagline
        VStack(spacing: Spacing.sm) {
          Image("AppLogo").resizable().frame(width: 64, height: 64)
          Text("Your tagline here")
            .font(.body(17))
            .foregroundColor(.textSecondary)
        }

        Spacer()

        // Auth buttons
        VStack(spacing: Spacing.md) {
          SignInWithAppleButton()
          GoogleSignInButton()
        }
        .padding(.horizontal, Spacing.lg)

        // Legal footer
        LegalFooterView()
          .padding(.bottom, Spacing.lg)
      }
    }
  }
}
```

---

### OnboardingView

Flow: Name → Problem → Solution/Commitment → Notification Setup → Paywall

```swift
// OnboardingViewModel.swift
class OnboardingViewModel: ObservableObject {
  @Published var currentStep = 0
  @Published var responses: [String: Any] = [:]

  // Quiz questions — configure per app
  let questions: [OnboardingQuestion] = [
    OnboardingQuestion(
      key: "name",
      headline: "What should we call you?",
      type: .textInput
    ),
    OnboardingQuestion(
      key: "primary_goal",
      headline: "What's your main goal?",
      type: .multipleChoice(options: [
        "Option A", "Option B", "Option C", "Option D"
      ])
    ),
    OnboardingQuestion(
      key: "commitment",
      headline: "How much time can you commit daily?",
      type: .multipleChoice(options: ["5 min", "10 min", "20 min", "30+ min"])
    ),
    // Transition screen — not a question
    OnboardingQuestion(
      key: "solution",
      headline: "Here's how [AppName] gets you there",
      type: .infoScreen(bullets: [
        "Personalized to your goals",
        "Takes less than 10 minutes daily",
        "See results in 7 days"
      ])
    ),
    OnboardingQuestion(
      key: "notifications",
      headline: "Set your daily reminder",
      type: .notificationSetup
    )
  ]

  func advance(answer: Any? = nil) {
    if let answer, let key = questions[currentStep].key {
      responses[key] = answer
    }
    HapticManager.selection()
    withAnimation(.spring(response: 0.4)) {
      currentStep += 1
    }
  }
}
```

**Next button** — bottom-right circular FAB:
```swift
// Bottom-right circular next button
Button(action: { vm.advance() }) {
  Image(feather: .chevronRight)
    .frame(width: 56, height: 56)
    .background(Color.accent)
    .foregroundColor(.white)
    .clipShape(Circle())
    .shadow(color: Color.accent.opacity(0.4), radius: 12, y: 4)
}
.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
.padding(Spacing.lg)
```

---

### Paywall — Screen 1: Trial Explainer

Goal: Eliminate fear. Focus on FREE.

```
┌─────────────────────────────┐
│                             │
│   🎉  Start Free Today      │  display(28) bold
│                             │
│   Timeline visualization:   │
│                             │
│   Today ─────── Day 7 ────── Day 8+  │
│   [Free]  [Still Free]  [Only if you stay]  │
│                             │
│   ✓  Full access starts now │
│   ✓  Reminder before charge │
│   ✓  Cancel anytime         │
│                             │
│   [Start My Free Trial  →]  │  primary button
│   [No thanks]               │  ghost button
│                             │
└─────────────────────────────┘
```

---

### Paywall — Screen 2: Plans

Goal: Convert. Anchor on yearly. Show value.

```
┌─────────────────────────────┐
│                             │
│   Everything you need to    │  display(22)
│   [achieve goal]            │
│                             │
│   ✓ Feature one             │
│   ✓ Feature two             │
│   ✓ Feature three           │
│   ✓ Feature four            │
│                             │
│ ┌───────────────────────┐   │
│ │  ⭐ YEARLY  BEST VALUE │   │  highlighted card, accent border
│ │  $29.99 / year        │   │
│ │  = $2.49/month        │   │
│ └───────────────────────┘   │
│                             │
│ ┌───────────────────────┐   │
│ │  Monthly              │   │
│ │  $7.99 / month        │   │
│ └───────────────────────┘   │
│                             │
│   [Start Free Trial  →]     │
│   [Restore Purchases]       │
│   Terms · Privacy           │
└─────────────────────────────┘
```

```swift
// PaywallViewModel.swift
class PaywallViewModel: ObservableObject {
  @Published var selectedPlan: Plan = .yearly
  @Published var isLoading = false

  enum Plan { case monthly, yearly }

  func purchase() async {
    isLoading = true
    HapticManager.medium()
    do {
      try await PaymentManager.shared.purchase(plan: selectedPlan)
      HapticManager.success()
      AppRouter.shared.advanceToHome()
    } catch {
      HapticManager.error()
    }
    isLoading = false
  }
}
```

---

### SettingsView

```swift
struct SettingsView: View {
  var body: some View {
    NavigationStack {
      List {
        // Account section
        Section("Account") {
          ProfileRow()
          NavigationLink("Manage Subscription") { SubscriptionView() }
        }

        // Preferences
        Section("Preferences") {
          ThemeToggleRow()
          NotificationRow()
        }

        // Support
        Section("Support") {
          LinkRow("Help & FAQ", url: "https://yourapp.com/help")
          LinkRow("Send Feedback", url: "mailto:hello@yourapp.com")
          LinkRow("Rate the App", action: AppStoreReview.request)
        }

        // Legal
        Section {
          LinkRow("Privacy Policy", url: "https://yourapp.com/privacy")
          LinkRow("Terms of Service", url: "https://yourapp.com/terms")
          Button("Sign Out", role: .destructive) { AuthManager.shared.signOut() }
        }
      }
      .navigationTitle("Settings")
    }
  }
}
```

---

## State Management Pattern

```
View  ←→  ViewModel (@StateObject / @ObservedObject)
              ↓
          Repository (async funcs, no UI knowledge)
              ↓
       ┌──────┴──────┐
   LocalDB        APIClient
  (SwiftData)    (Supabase / Hono)
```

- ViewModels are `@MainActor` classes
- All async work uses `async/await`  
- No Combine unless necessary
- `@AppStorage` for simple persistent prefs
- SwiftData for local-first data

---

## AppRouter

```swift
// AppRouter.swift
@MainActor
class AppRouter: ObservableObject {
  static let shared = AppRouter()

  @Published var path = NavigationPath()
  @Published var root: RootDestination = .splash

  enum RootDestination {
    case splash, login, onboarding, paywall, home
  }

  func advance() {
    // Logic: splash → check auth → check onboarding → check paywall → home
    Task {
      if AuthManager.shared.isAuthenticated {
        if OnboardingManager.shared.isComplete {
          root = .home
        } else {
          root = .onboarding
        }
      } else {
        root = .login
      }
    }
  }
}
```

---

## Local-First Sync

```swift
// SyncManager.swift
// On launch: load from local SwiftData immediately (no loading state)
// In background: fetch from API + merge
// On write: write locally first, queue for API sync
// On conflict: server wins (last-write-wins), client shows reconciled state
```

---

## Analytics Events (Typed)

```swift
// Analytics.swift
enum AnalyticsEvent {
  // Auth
  case login(method: String)
  case logout

  // Onboarding
  case onboardingStarted
  case onboardingStepCompleted(step: Int, key: String)
  case onboardingCompleted

  // Paywall
  case paywallViewed(screen: Int)
  case planSelected(plan: String)
  case trialStarted
  case subscriptionPurchased(plan: String, price: Double)
  case paywallDismissed

  // Core feature — add app-specific events here
  case featureUsed(name: String)
}

extension Analytics {
  static func track(_ event: AnalyticsEvent) {
    PostHogSDK.shared.capture(event.name, properties: event.properties)
  }
}
```

---

## Setup Steps

1. Clone repo, open `ios/` in Xcode
2. Update Bundle ID: `com.yourstudio.appname`
3. Add SPM packages (see above)
4. Configure `AppEnvironment.swift` with Supabase URL + anon key
5. Add `GoogleService-Info.plist` for Google Sign-In
6. Configure RevenueCat API key in `PaymentManager.swift`
7. Add PostHog API key in `Analytics.swift`
8. Update `Assets.xcassets` with app icon + logo
9. Replace placeholder colors in `Colors/` with brand colors
10. Build ⌘B, run ⌘R
