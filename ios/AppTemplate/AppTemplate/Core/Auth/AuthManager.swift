import Foundation

#if canImport(Supabase)
import Supabase

// MARK: - AuthManager
// Single source of truth for auth state. Wraps the Supabase client.

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    let client = SupabaseClient(
        supabaseURL: URL(string: AppEnvironment.supabaseURL)!,
        supabaseKey: AppEnvironment.supabaseAnonKey,
        options: .init(auth: .init(emitLocalSessionAsInitialSession: true))
    )

    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUser: User?

    init() {
        Task { await refreshSession() }
    }

    // MARK: - Session

    var accessToken: String? {
        get async {
            try? await client.auth.session.accessToken
        }
    }

    func refreshSession() async {
        do {
            let session = try await client.auth.session
            currentUser = session.user
            isAuthenticated = true
            Analytics.identify(userId: session.user.id.uuidString)
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }

    // MARK: - Social Sign-In via ID Token

    /// Called by AppleSignInManager after obtaining the Apple identity token.
    func signInWithApple(idToken: String, nonce: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        await refreshSession()
        if let uid = currentUser?.id.uuidString {
            Analytics.identify(userId: uid)
            try? await PaymentManager.shared.logIn(userId: uid)
        }
    }

    /// Called by GoogleSignInManager after obtaining the Google ID token.
    func signInWithGoogle(idToken: String, accessToken: String?) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .google, idToken: idToken, accessToken: accessToken)
        )
        await refreshSession()
        if let uid = currentUser?.id.uuidString {
            Analytics.identify(userId: uid)
            try? await PaymentManager.shared.logIn(userId: uid)
        }
    }

    // MARK: - Sign Out

    func signOut() {
        Task {
            try? await client.auth.signOut()
            try? await PaymentManager.shared.logOut()
            Analytics.reset()
            isAuthenticated = false
            currentUser = nil
        }
    }
}

#else
// MARK: - Stub (compiles without Supabase package)

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUser: AppUser? = nil

    var accessToken: String? { get async { nil } }

    func refreshSession() async {}
    func signInWithApple(idToken: String, nonce: String) async throws {}
    func signInWithGoogle(idToken: String, accessToken: String?) async throws {}
    func signOut() { isAuthenticated = false }
}
#endif
