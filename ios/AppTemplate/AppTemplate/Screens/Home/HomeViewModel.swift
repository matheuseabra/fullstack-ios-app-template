import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var subscription: Subscription?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        async let userFetch: UserResponse   = APIClient.shared.get(APIEndpoints.me)
        async let subFetch: SubscriptionResponse = APIClient.shared.get(APIEndpoints.subscription)

        do {
            let (userResp, subResp) = try await (userFetch, subFetch)
            user = userResp.data
            subscription = subResp.data
        } catch APIError.unauthorized {
            AppRouter.shared.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reload() async {
        errorMessage = nil
        await load()
    }
}
