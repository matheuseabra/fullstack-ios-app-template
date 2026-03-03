import Foundation
import UIKit

#if canImport(GoogleSignIn)
import GoogleSignIn

// MARK: - GoogleSignInManager

@MainActor
final class GoogleSignInManager: ObservableObject {
    static let shared = GoogleSignInManager()

    @Published private(set) var isLoading = false

    /// Call once at app launch (after PaymentManager.configure).
    func configure() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: AppEnvironment.googleClientID,
            serverClientID: AppEnvironment.googleWebClientID
        )
    }

    func signIn() async throws {
        isLoading = true
        defer { isLoading = false }

        print("[GoogleSignIn] Starting sign-in...")
        print("[GoogleSignIn] clientID: \(AppEnvironment.googleClientID)")
        print("[GoogleSignIn] serverClientID: \(AppEnvironment.googleWebClientID)")

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            print("[GoogleSignIn] ❌ No rootViewController found")
            throw AuthManagerError.missingToken
        }

        print("[GoogleSignIn] Presenting sign-in sheet...")
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

        print("[GoogleSignIn] Sign-in returned. User email: \(result.user.profile?.email ?? "nil")")
        print("[GoogleSignIn] idToken present: \(result.user.idToken != nil)")
        print("[GoogleSignIn] accessToken: \(result.user.accessToken.tokenString.prefix(20))...")

        guard let idToken = result.user.idToken?.tokenString else {
            print("[GoogleSignIn] ❌ idToken is nil — serverClientID may not be set correctly")
            throw AuthManagerError.missingToken
        }

        print("[GoogleSignIn] ✅ idToken obtained, passing to Supabase...")
        let accessToken = result.user.accessToken.tokenString
        try await AuthManager.shared.signInWithGoogle(idToken: idToken, accessToken: accessToken)
        print("[GoogleSignIn] ✅ Supabase sign-in complete")
    }
}

#else
// MARK: - Stub (compiles without GoogleSignIn package)

@MainActor
final class GoogleSignInManager: ObservableObject {
    static let shared = GoogleSignInManager()
    @Published private(set) var isLoading = false

    func configure() {}

    func signIn() async throws {
        throw AuthManagerError.missingToken
    }
}
#endif
