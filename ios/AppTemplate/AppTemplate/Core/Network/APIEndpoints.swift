import Foundation

// MARK: - API Endpoints
// Replace baseURL with your production/staging backend URL.

enum APIEndpoints {
    
    static let baseURL = AppEnvironment.backendURL

    // Users
    static let me               = "\(baseURL)/api/users/me"
    static let settings         = "\(baseURL)/api/users/me/settings"

    // Onboarding
    static let onboardingResponses = "\(baseURL)/api/onboarding/responses"

    // Subscriptions
    static let subscription     = "\(baseURL)/api/subscriptions/me"

    // Usage
    static func usage(_ feature: String) -> String {
        "\(baseURL)/api/usage/\(feature)"
    }

    // Notifications
    static let notificationToken        = "\(baseURL)/api/notifications/token"
    static let notificationPreferences  = "\(baseURL)/api/notifications/preferences"
}
