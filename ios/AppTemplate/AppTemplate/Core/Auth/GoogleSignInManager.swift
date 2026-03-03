import Foundation

// MARK: - GoogleSignInManager
// Wraps Google Sign-In SDK.
// Add the GoogleSignIn-iOS package via Xcode → File → Add Package Dependencies,
// then remove the #if canImport guard and uncomment the real implementation.

#if canImport(GoogleSignIn)
import GoogleSignIn

@MainActor
final class GoogleSignInManager: ObservableObject {
    static let shared = GoogleSignInManager()

    @Published private(set) var isLoading = false
    @Published var error: Error?

    // TODO: Set your Google OAuth client ID in AppEnvironment
    func configure() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: AppEnvironment.googleClientID
        )
    }

    func signIn() async throws {
        isLoading = true
        defer { isLoading = false }

        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = await windowScene.windows.first?.rootViewController else {
            throw AuthManagerError.missingToken
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthManagerError.missingToken
        }

#if canImport(Supabase)
        // Exchange Google token for Supabase session
        // try await supabaseClient.auth.signInWithIdToken(credentials: .init(provider: .google, idToken: idToken))
        // await AuthManager.shared.refreshSession()
        _ = idToken
#else
        await AuthManager.shared.setAuthenticated(token: idToken)
#endif
    }
}

#else
// MARK: - Stub (compiles without GoogleSignIn package)

@MainActor
final class GoogleSignInManager: ObservableObject {
    static let shared = GoogleSignInManager()

    @Published private(set) var isLoading = false
    @Published var error: Error?

    func configure() {
        // TODO: Install GoogleSignIn-iOS via SPM
    }

    func signIn() async throws {
        // TODO: Install GoogleSignIn-iOS via SPM
        throw AuthManagerError.missingToken
    }
}
#endif

import UIKit
