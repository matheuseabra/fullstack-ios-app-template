import Foundation
import SwiftData

// MARK: - TaskItem
// Local-first SwiftData model for tasks.
// Mirrors the `tasks` table in Supabase. syncStatus tracks offline changes.

@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var note: String
    var isCompleted: Bool
    var priority: Priority
    var dueDate: Date?
    var completedAt: Date?
    var categoryId: String?
    var categoryName: String?
    var categoryEmoji: String?
    var repeatFrequency: RepeatFrequency?
    var seriesId: String?
    var createdAt: Date
    var updatedAt: Date

    // Sync metadata
    var supabaseId: String?
    var syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        title: String,
        note: String = "",
        isCompleted: Bool = false,
        priority: Priority = .medium,
        dueDate: Date? = nil,
        completedAt: Date? = nil,
        categoryId: String? = nil,
        categoryName: String? = nil,
        categoryEmoji: String? = nil,
        repeatFrequency: RepeatFrequency? = nil,
        seriesId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        supabaseId: String? = nil,
        syncStatus: SyncStatus = .pendingUpload
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.isCompleted = isCompleted
        self.priority = priority
        self.dueDate = dueDate
        self.completedAt = completedAt
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.categoryEmoji = categoryEmoji
        self.repeatFrequency = repeatFrequency
        self.seriesId = seriesId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.supabaseId = supabaseId
        self.syncStatus = syncStatus
    }

    // MARK: - Priority

    enum Priority: String, Codable, CaseIterable {
        case low, medium, high

        var label: String {
            switch self {
            case .low:    return "Low"
            case .medium: return "Medium"
            case .high:   return "High"
            }
        }

        var color: String {
            switch self {
            case .low:    return "success"
            case .medium: return "warning"
            case .high:   return "danger"
            }
        }

        var icon: String {
            switch self {
            case .low:    return "arrow.down"
            case .medium: return "arrow.right"
            case .high:   return "arrow.up"
            }
        }
    }

    enum RepeatFrequency: String, Codable, CaseIterable, Identifiable {
        case daily, weekly, monthly, yearly

        var id: String { rawValue }

        var label: String {
            switch self {
            case .daily:   return "Daily"
            case .weekly:  return "Weekly"
            case .monthly: return "Monthly"
            case .yearly:  return "Yearly"
            }
        }

        var shortLabel: String {
            rawValue
        }

        var icon: String {
            switch self {
            case .daily:   return "sun.max"
            case .weekly:  return "calendar.badge.clock"
            case .monthly: return "calendar"
            case .yearly:  return "sparkles"
            }
        }
    }

    // MARK: - SyncStatus

    enum SyncStatus: String, Codable {
        case synced
        case pendingUpload
        case pendingUpdate
        case pendingDelete
    }

    var categoryDisplayText: String? {
        guard let categoryName, !categoryName.isEmpty else { return nil }
        let emoji = categoryEmoji?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return emoji.isEmpty ? categoryName : "\(emoji) \(categoryName)"
    }

    var repeatDisplayText: String? {
        repeatFrequency?.label
    }
}

// MARK: - Codable DTO for API

struct TaskCategory: Codable, Identifiable, Equatable {
    let id: String
    let userId: String?
    let name: String
    let emoji: String
    let slug: String?
    let isDefault: Bool
    let createdAt: Date?
    let updatedAt: Date?

    static let defaults: [TaskCategory] = [
        .init(id: "default-work", userId: nil, name: "Work", emoji: "💼", slug: "work", isDefault: true, createdAt: nil, updatedAt: nil),
        .init(id: "default-relationship", userId: nil, name: "Relationship", emoji: "❤️", slug: "relationship", isDefault: true, createdAt: nil, updatedAt: nil),
        .init(id: "default-goals", userId: nil, name: "Goals", emoji: "🎯", slug: "goals", isDefault: true, createdAt: nil, updatedAt: nil),
        .init(id: "default-social", userId: nil, name: "Social", emoji: "🥂", slug: "social", isDefault: true, createdAt: nil, updatedAt: nil),
        .init(id: "default-health", userId: nil, name: "Health", emoji: "💪", slug: "health", isDefault: true, createdAt: nil, updatedAt: nil),
    ]

    static func localCustom(name: String, emoji: String) -> TaskCategory {
        TaskCategory(
            id: UUID().uuidString,
            userId: nil,
            name: name,
            emoji: emoji,
            slug: nil,
            isDefault: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    var displayText: String {
        "\(emoji) \(name)"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case emoji
        case slug
        case isDefault = "is_default"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct TaskDTO: Codable {
    let id: String?
    let title: String
    let note: String?
    let isCompleted: Bool
    let priority: String
    let dueDate: Date?
    let completedAt: Date?
    let categoryId: String?
    let categoryName: String?
    let categoryEmoji: String?
    let categorySlug: String?
    let categoryIsDefault: Bool?
    let repeatFrequency: TaskItem.RepeatFrequency?
    let seriesId: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case note
        case isCompleted  = "is_completed"
        case priority
        case dueDate      = "due_date"
        case completedAt  = "completed_at"
        case categoryId   = "category_id"
        case categoryName = "category_name"
        case categoryEmoji = "category_emoji"
        case categorySlug = "category_slug"
        case categoryIsDefault = "category_is_default"
        case repeatFrequency = "repeat_frequency"
        case seriesId = "series_id"
        case createdAt    = "created_at"
        case updatedAt    = "updated_at"
    }
}

struct TaskResponse: Decodable {
    let ok: Bool
    let data: TaskDTO
}

struct TaskListResponse: Decodable {
    let ok: Bool
    let data: [TaskDTO]
}

struct TaskMutationPayload: Decodable {
    let task: TaskDTO
    let nextOccurrence: TaskDTO?

    enum CodingKeys: String, CodingKey {
        case task
        case nextOccurrence = "next_occurrence"
    }
}

struct TaskMutationResponse: Decodable {
    let ok: Bool
    let data: TaskMutationPayload
}

struct TaskCategoryResponse: Decodable {
    let ok: Bool
    let data: TaskCategory
}

struct TaskCategoryListResponse: Decodable {
    let ok: Bool
    let data: [TaskCategory]
}
