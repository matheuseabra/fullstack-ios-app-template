import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        do {
            let resp: UserResponse = try await APIClient.shared.get(APIEndpoints.me)
            user = resp.data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        Analytics.track(.logout)
        HapticManager.medium()
        AppRouter.shared.signOut()
    }
}
