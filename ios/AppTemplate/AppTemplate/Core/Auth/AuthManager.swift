import Foundation

// MARK: - AuthManager
// Wraps Supabase authentication.
// Add the supabase-swift package via Xcode → File → Add Package Dependencies
// then remove the #if canImport guard and uncomment the real implementation.

#if canImport(Supabase)
import Supabase

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    private let client = SupabaseClient(
        supabaseURL: URL(string: AppEnvironment.supabaseURL)!,
        supabaseKey: AppEnvironment.supabaseAnonKey
    )

    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUser: User?

    init() {
        Task { await refreshSession() }
    }

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
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }

    func signOut() {
        Task {
            try? await client.auth.signOut()
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

    var accessToken: String? {
        get async { nil }
    }

    func refreshSession() async {}
    func signOut() { isAuthenticated = false }

    /// Called by AppleSignInManager / GoogleSignInManager after exchanging tokens
    func setAuthenticated(token: String) {
        isAuthenticated = true
    }
}
#endif
