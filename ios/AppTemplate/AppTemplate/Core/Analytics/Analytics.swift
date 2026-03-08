import Foundation
#if canImport(PostHog)
import PostHog
#endif

// MARK: - Analytics
// Typed analytics wrapper. Swap the underlying SDK by changing the capture call.
// Add PostHog via Xcode → File → Add Package Dependencies,
// then remove the #if canImport guard.

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

    // MARK: - Event Name + Properties

    var name: String {
        switch self {
        case .login:                      return "login"
        case .logout:                     return "logout"
        case .onboardingStarted:          return "onboarding_started"
        case .onboardingStepCompleted:    return "onboarding_step_completed"
        case .onboardingCompleted:        return "onboarding_completed"
        case .paywallViewed:              return "paywall_viewed"
        case .planSelected:               return "plan_selected"
        case .trialStarted:               return "trial_started"
        case .subscriptionPurchased:      return "subscription_purchased"
        case .paywallDismissed:           return "paywall_dismissed"
        case .featureUsed:                return "feature_used"
        }
    }

    var properties: [String: Any] {
        switch self {
        case .login(let method):
            return ["method": method]
        case .onboardingStepCompleted(let step, let key):
            return ["step": step, "key": key]
        case .paywallViewed(let screen):
            return ["screen": screen]
        case .planSelected(let plan):
            return ["plan": plan]
        case .subscriptionPurchased(let plan, let price):
            return ["plan": plan, "price": price]
        case .featureUsed(let name):
            return ["feature": name]
        default:
            return [:]
        }
    }
}

// MARK: - Analytics Wrapper

enum Analytics {
    static func track(_ event: AnalyticsEvent) {
#if canImport(PostHog)
        PostHogSDK.shared.capture(event.name, properties: event.properties)
#else
        // TODO: Install posthog-ios via SPM
        print("[Analytics] \(event.name): \(event.properties)")
#endif
    }

    /// Call on app launch with your PostHog write key.
    static func configure(apiKey: String, host: String = "https://us.i.posthog.com") {
#if canImport(PostHog)
        let config = PostHogConfig(apiKey: apiKey, host: host)
        PostHogSDK.shared.setup(config)
#else
        print("[Analytics] PostHog not installed — configure after adding SPM package")
#endif
    }

    static func identify(userId: String, traits: [String: Any] = [:]) {
#if canImport(PostHog)
        PostHogSDK.shared.identify(userId, userProperties: traits)
#endif
    }

    static func reset() {
#if canImport(PostHog)
        PostHogSDK.shared.reset()
#endif
    }
}
