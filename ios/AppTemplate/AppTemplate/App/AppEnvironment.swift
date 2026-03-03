import Foundation

// MARK: - App Environment Configuration
// Replace placeholder values with your own before running.
// For production: inject via Xcode build settings / xcconfig to avoid hardcoding secrets.

enum AppEnvironment {
    // Supabase (local instance)
    static let supabaseURL     = "http://127.0.0.1:54321"
    static let supabaseAnonKey = "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"

    // TODO: Replace with your Google OAuth client ID (from GoogleService-Info.plist)
    static let googleClientID  = "YOUR_GOOGLE_CLIENT_ID"

    // RevenueCat iOS public API key
    static let revenueCatKey   = "test_byvGVMQjPyrvbuSdqAbadXJQrXU"

    // PostHog
    static let postHogKey      = "phx_UB8omil1ZdDayosdoJ4MKh6txPhhd8Hcx8KrJw97TA2nV19"

    // Backend
    static let backendURL      = "http://localhost:3000"
}
