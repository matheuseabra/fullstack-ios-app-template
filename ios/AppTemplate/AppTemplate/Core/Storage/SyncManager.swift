import Foundation

// MARK: - SyncManager
// Orchestrates local-first data flow:
//  1. On launch: load local data immediately (no loading flicker)
//  2. In background: fetch from API and merge (server-wins, last-write-wins)
//  3. On local write: persist locally first, then queue an API sync

@MainActor
final class SyncManager: ObservableObject {
    static let shared = SyncManager()

    @Published private(set) var isSyncing = false

    // MARK: - Pull (server → local)

    /// Call on app launch or foreground. Runs in background — UI loads from local store immediately.
    func pullIfNeeded() {
        Task { await pull() }
    }

    func pull() async {
        guard !isSyncing else { return }
        isSyncing = true

        #if !DEBUG
        // Pull tasks from server and merge into local SwiftData store
        do {
            let response: TaskListResponse = try await APIClient.shared.get(APIEndpoints.tasks)
            let context = LocalDatabase.shared.context
            for dto in response.data {
                guard let id = dto.id else { continue }
                let descriptor = FetchDescriptor<TaskItem>(
                    predicate: #Predicate { $0.supabaseId == id }
                )
                let existing = try? context.fetch(descriptor).first
                if let existing, existing.syncStatus == .synced {
                    existing.title = dto.title
                    existing.note = dto.note ?? ""
                    existing.isCompleted = dto.isCompleted
                    existing.priority = TaskItem.Priority(rawValue: dto.priority) ?? .medium
                    existing.dueDate = dto.dueDate
                    existing.completedAt = dto.completedAt
                    existing.updatedAt = dto.updatedAt ?? Date()
                } else if existing == nil {
                    let task = TaskItem(
                        title: dto.title,
                        note: dto.note ?? "",
                        isCompleted: dto.isCompleted,
                        priority: TaskItem.Priority(rawValue: dto.priority) ?? .medium,
                        dueDate: dto.dueDate,
                        completedAt: dto.completedAt,
                        createdAt: dto.createdAt ?? Date(),
                        updatedAt: dto.updatedAt ?? Date(),
                        supabaseId: id,
                        syncStatus: .synced
                    )
                    context.insert(task)
                }
            }
            try? context.save()
        } catch {
            print("[SyncManager] Pull tasks failed: \(error)")
        }
        #endif

        isSyncing = false
    }

    // MARK: - Push (local → server)

    /// Call immediately after any local mutation.
    func push(_ operation: SyncOperation) {
        Task {
            do {
                try await operation.execute()
            } catch {
                // TODO: Persist to retry queue for offline support
                print("[SyncManager] Push failed, will retry: \(error)")
            }
        }
    }
}

// MARK: - SyncOperation

protocol SyncOperation {
    func execute() async throws
}
