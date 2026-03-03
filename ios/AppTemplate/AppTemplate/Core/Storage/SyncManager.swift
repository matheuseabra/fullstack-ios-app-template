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

        // TODO: For each entity type:
        //   1. Fetch from APIClient
        //   2. Compare updatedAt timestamps with local cache
        //   3. Overwrite local when server is newer (server-wins)
        //   e.g.:
        //   let remoteUser: UserResponse = try await APIClient.shared.get(APIEndpoints.me)
        //   LocalDatabase.shared.upsert(remoteUser)

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
