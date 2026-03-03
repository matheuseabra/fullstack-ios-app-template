import Foundation

// MARK: - Subscription
// Maps to the `subscriptions` table in Supabase.

struct Subscription: Codable, Identifiable {
    let id: String
    let productId: String
    let status: Status
    let trialEndsAt: Date?
    let currentPeriodEnd: Date?
    let cancelAtPeriodEnd: Bool
    let entitlements: Entitlements
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case productId         = "product_id"
        case status
        case trialEndsAt       = "trial_ends_at"
        case currentPeriodEnd  = "current_period_end"
        case cancelAtPeriodEnd = "cancel_at_period_end"
        case entitlements
        case createdAt         = "created_at"
        case updatedAt         = "updated_at"
    }

    // MARK: - Status

    enum Status: String, Codable {
        case active
        case trialing
        case pastDue  = "past_due"
        case canceled
        case expired
        case unknown

        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Status(rawValue: raw) ?? .unknown
        }
    }

    // MARK: - Entitlements

    struct Entitlements: Codable {
        let ids: [String]

        var isPro: Bool { ids.contains("pro") }
    }

    // MARK: - Derived

    var isActive: Bool { status == .active || status == .trialing }

    var isInTrial: Bool {
        status == .trialing
        && trialEndsAt.map { $0 > Date() } ?? false
    }
}

// MARK: - API Response Wrappers

struct SubscriptionResponse: Decodable {
    let ok: Bool
    let data: Subscription?
}
