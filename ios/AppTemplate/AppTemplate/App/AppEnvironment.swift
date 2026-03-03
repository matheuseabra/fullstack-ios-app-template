import Foundation

// MARK: - App Environment Configuration
// Replace placeholder values with your own before running.
// For production: inject via Xcode build settings / xcconfig to avoid hardcoding secrets.

enum AppEnvironment {
    // TODO: Replace with your Supabase project URL + anon key
    static let supabaseURL     = "https://YOUR_PROJECT_ID.supabase.co"
    static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"

    // TODO: Replace with your Google OAuth client ID (from GoogleService-Info.plist)
    static let googleClientID  = "YOUR_GOOGLE_CLIENT_ID"

    // TODO: Replace with your RevenueCat API key
    static let revenueCatKey   = "YOUR_REVENUECAT_API_KEY"

    // TODO: Replace with your PostHog API key
    static let postHogKey      = "YOUR_POSTHOG_API_KEY"

    // TODO: Replace with your backend URL (local: http://localhost:3000)
    static let backendURL      = "http://localhost:3000"
}
