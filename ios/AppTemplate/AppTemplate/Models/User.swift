import Foundation

// MARK: - AppUser
// Maps to the `profiles` table in Supabase.
// Named AppUser to avoid collision with Supabase's User type.

struct AppUser: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    var fullName: String?
    var avatarURL: String?
    var timezone: String?
    var locale: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName    = "full_name"
        case avatarURL   = "avatar_url"
        case timezone
        case locale
        case createdAt   = "created_at"
        case updatedAt   = "updated_at"
    }
}

// MARK: - Update Request

struct UpdateProfileRequest: Encodable {
    let fullName: String?
    let avatarURL: String?
    let timezone: String?
    let locale: String?

    enum CodingKeys: String, CodingKey {
        case fullName  = "full_name"
        case avatarURL = "avatar_url"
        case timezone
        case locale
    }
}

// MARK: - API Response Wrappers

struct UserResponse: Decodable {
    let ok: Bool
    let data: AppUser
}
