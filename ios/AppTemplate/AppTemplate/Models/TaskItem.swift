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

    // MARK: - SyncStatus

    enum SyncStatus: String, Codable {
        case synced
        case pendingUpload
        case pendingUpdate
        case pendingDelete
    }
}

// MARK: - Codable DTO for API

struct TaskDTO: Codable {
    let id: String?
    let title: String
    let note: String?
    let isCompleted: Bool
    let priority: String
    let dueDate: Date?
    let completedAt: Date?
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
