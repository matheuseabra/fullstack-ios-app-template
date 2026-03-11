import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var subscription: Subscription?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        if !AppEnvironment.useLiveBackend {
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
            subscription = nil
            return
        }

        do {
            async let userFetch: UserResponse = APIClient.shared.get(APIEndpoints.me)
            async let subFetch: SubscriptionResponse = APIClient.shared.get(APIEndpoints.subscription)
            let (userResp, subResp) = try await (userFetch, subFetch)
            user = userResp.data
            subscription = subResp.data
        } catch APIError.unauthorized {
            AppRouter.shared.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        Analytics.track(.logout)
        HapticManager.medium()
        AppRouter.shared.signOut()
    }

    var subscriptionLabel: String {
        guard let subscription else { return "Free" }

        switch subscription.status {
        case .active:
            return "Active"
        case .trialing:
            return "Trial"
        case .pastDue:
            return "Past Due"
        case .canceled:
            return "Canceled"
        case .expired:
            return "Expired"
        case .unknown:
            return "Unknown"
        }
    }
}
