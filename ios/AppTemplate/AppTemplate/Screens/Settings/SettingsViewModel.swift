import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
#if DEBUG
        user = AppUser(
            id: "debug",
            email: "debug@test.com",
            fullName: "Debug User",
            avatarURL: nil,
            timezone: "UTC",
            locale: "en",
            createdAt: Date(),
            updatedAt: Date()
        )
#else
        do {
            let resp: UserResponse = try await APIClient.shared.get(APIEndpoints.me)
            user = resp.data
        } catch {
            errorMessage = error.localizedDescription
        }
#endif
    }

    func signOut() {
        Analytics.track(.logout)
        HapticManager.medium()
        AppRouter.shared.signOut()
    }
}
