import Foundation
import SwiftDotenv

// MARK: - App Environment Configuration
// Reads from ios/.env at build time via #filePath.
// Copy ios/.env.example → ios/.env and fill in your secrets.

enum AppEnvironment {

    // MARK: - Bootstrap (call once before accessing any property)

    static func load() {
        guard let path = Bundle.main.path(forResource: "Env", ofType: nil),
              let data = FileManager.default.contents(atPath: path),
              let contents = String(data: data, encoding: .utf8) else {
            fatalError(
                "Missing Env file in bundle. "
                + "Copy AppTemplate/Env.example → AppTemplate/Env and fill in your secrets."
            )
        }

        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
            guard let eqIndex = trimmed.firstIndex(of: "=") else { continue }
            let key = String(trimmed[..<eqIndex])
                .trimmingCharacters(in: .whitespaces)
            let value = String(trimmed[trimmed.index(after: eqIndex)...])
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            guard !key.isEmpty else { continue }
            Dotenv.set(value: value, forKey: key)
        }
    }

    // MARK: - Helpers

    private static func required(_ key: String) -> String {
        guard let value = Dotenv[key]?.stringValue else {
            fatalError("Missing required env var: \(key) — check your ios/.env file")
        }
        return value
    }

    // MARK: - Supabase

    static var supabaseURL: String     { required("SUPABASE_URL") }
    static var supabaseAnonKey: String { required("SUPABASE_ANON_KEY") }

    // MARK: - Google OAuth

    static var googleClientID: String    { required("GOOGLE_CLIENT_ID") }
    static var googleWebClientID: String { required("GOOGLE_WEB_CLIENT_ID") }

    // MARK: - RevenueCat

    static var revenueCatKey: String { required("REVENUECAT_KEY") }

    // MARK: - PostHog

    static var postHogKey: String { required("POSTHOG_KEY") }

    // MARK: - Backend

    static var backendURL: String { required("BACKEND_URL") }

    // MARK: - Feature Flags
    //
    // Toggle entire features on/off. The app adapts its navigation flow,
    // service initialization, and UI sections based on these flags.
    //
    // Presets:
    //   Full app     → all true (default)
    //   MVP/prototype → enableAuth=false, enableOnboarding=false, enablePaywall=false
    //   Freemium     → enablePaywall=false, everything else true

    // ── Top-level features ──────────────────────────────────────────

    /// Master auth toggle. When false the app skips login entirely and
    /// runs in local-only mode (no backend sync, no JWT).
    static var enableAuth: Bool           { Dotenv["ENABLE_AUTH"]?.stringValue != "false" }

    /// Show the onboarding quiz after first sign-in.
    static var enableOnboarding: Bool     { Dotenv["ENABLE_ONBOARDING"]?.stringValue != "false" }

    /// Gate access behind a paywall / subscription screen.
    static var enablePaywall: Bool        { Dotenv["ENABLE_PAYWALL"]?.stringValue != "false" }

    /// Push notifications registration and reminder setup.
    static var enableNotifications: Bool  { Dotenv["ENABLE_NOTIFICATIONS"]?.stringValue != "false" }

    /// PostHog product analytics.
    static var enableAnalytics: Bool      { Dotenv["ENABLE_ANALYTICS"]?.stringValue != "false" }

    // ── Auth sub-flags (only relevant when enableAuth is true) ──────

    static var enableAppleSignIn: Bool  { Dotenv["ENABLE_APPLE_SIGN_IN"]?.stringValue == "true" }
    static var enableGoogleSignIn: Bool { Dotenv["ENABLE_GOOGLE_SIGN_IN"]?.stringValue != "false" }
}
