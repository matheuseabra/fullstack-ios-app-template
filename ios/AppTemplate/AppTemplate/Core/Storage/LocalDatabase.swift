import Foundation
import SwiftData

// MARK: - Local Database
// SwiftData container setup. Add your @Model types below.

@MainActor
final class LocalDatabase {
    static let shared = LocalDatabase()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            // TODO: Add your @Model types here as the app grows.
            // Example: CachedUser.self, CachedSubscription.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("[LocalDatabase] Could not create ModelContainer: \(error)")
        }
    }

    var context: ModelContext {
        container.mainContext
    }
}
