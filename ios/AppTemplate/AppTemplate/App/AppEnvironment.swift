import Foundation

// MARK: - App Environment Configuration
// Replace placeholder values with your own before running.
// For production: inject via Xcode build settings / xcconfig to avoid hardcoding secrets.

enum AppEnvironment {
    // Supabase (tunnelled via ngrok)
    static let supabaseURL     = "https://341f-179-180-34-209.ngrok-free.app"
    static let supabaseAnonKey = "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"

    // Google OAuth
    // iOS client ID — from Google Cloud Console → Credentials → iOS type
    static let googleClientID    = "349460612215-f93pi78toa8oetkj2a994j2uhnn877m2.apps.googleusercontent.com"
    // Web client ID — from Google Cloud Console → Credentials → Web type (needed by Supabase to verify the ID token)
    static let googleWebClientID = "349460612215-fhvp7vlgnteaj6ufr0nbnnvfm8v4usrt.apps.googleusercontent.com"

    // RevenueCat iOS public API key
    static let revenueCatKey   = "test_byvGVMQjPyrvbuSdqAbadXJQrXU"

    // PostHog
    static let postHogKey      = "phx_UB8omil1ZdDayosdoJ4MKh6txPhhd8Hcx8KrJw97TA2nV19"

    // Backend (tunnelled via ngrok)
    static let backendURL      = "https://2d20-179-180-34-209.ngrok-free.app"
}
