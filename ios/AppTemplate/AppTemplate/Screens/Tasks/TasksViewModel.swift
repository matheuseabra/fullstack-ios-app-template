import Foundation
import SwiftData
import SwiftUI

// MARK: - TasksViewModel
// Drives the task manager UI. Reads from SwiftData (local-first),
// syncs to backend in background.

@MainActor
final class TasksViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var user: AppUser?
    @Published var subscription: Subscription?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDate: Date = Date()

    private var modelContext: ModelContext {
        LocalDatabase.shared.context
    }

    // MARK: - Load

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        // Load local tasks immediately
        fetchLocal()

        // Fetch user + subscription from API
        #if DEBUG
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
        #else
        async let userFetch: UserResponse = APIClient.shared.get(APIEndpoints.me)
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

        // Pull remote tasks
        await syncFromServer()
        #endif
    }

    func reload() async {
        errorMessage = nil
        await load()
    }

    // MARK: - Local CRUD

    func fetchLocal() {
        let descriptor = FetchDescriptor<TaskItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            tasks = try modelContext.fetch(descriptor)
        } catch {
            print("[TasksVM] Failed to fetch local tasks: \(error)")
        }
    }

    func addTask(title: String, note: String = "", priority: TaskItem.Priority = .medium, dueDate: Date? = nil) {
        let task = TaskItem(
            title: title,
            note: note,
            priority: priority,
            dueDate: dueDate
        )
        modelContext.insert(task)
        saveContext()
        fetchLocal()

        HapticManager.success()
        Analytics.track(.featureUsed(name: "task_created"))

        // Sync to server
        #if !DEBUG
        Task { await pushTask(task) }
        #endif
    }

    func toggleComplete(_ task: TaskItem) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date() : nil
        task.updatedAt = Date()
        task.syncStatus = .pendingUpdate
        saveContext()
        fetchLocal()

        HapticManager.light()
        Analytics.track(.featureUsed(name: task.isCompleted ? "task_completed" : "task_uncompleted"))

        #if !DEBUG
        Task { await updateTaskOnServer(task) }
        #endif
    }

    func deleteTask(_ task: TaskItem) {
        let supabaseId = task.supabaseId
        modelContext.delete(task)
        saveContext()
        fetchLocal()

        HapticManager.medium()
        Analytics.track(.featureUsed(name: "task_deleted"))

        #if !DEBUG
        if let id = supabaseId {
            Task { await deleteTaskOnServer(id) }
        }
        #endif
    }

    func updateTask(_ task: TaskItem, title: String, note: String, priority: TaskItem.Priority, dueDate: Date?) {
        task.title = title
        task.note = note
        task.priority = priority
        task.dueDate = dueDate
        task.updatedAt = Date()
        task.syncStatus = .pendingUpdate
        saveContext()
        fetchLocal()

        #if !DEBUG
        Task { await updateTaskOnServer(task) }
        #endif
    }

    // MARK: - Derived Data

    var tasksForSelectedDate: [TaskItem] {
        tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: selectedDate)
        }
    }

    var todayTasks: [TaskItem] {
        tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDateInToday(dueDate)
        }
    }

    var completedToday: Int {
        todayTasks.filter(\.isCompleted).count
    }

    var totalToday: Int {
        todayTasks.count
    }

    var completionRate: Double {
        guard totalToday > 0 else { return 0 }
        return Double(completedToday) / Double(totalToday)
    }

    var pendingTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }
    }

    var completedTasks: [TaskItem] {
        tasks.filter(\.isCompleted)
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = user?.fullName?.components(separatedBy: " ").first ?? ""
        let prefix: String
        switch hour {
        case 5..<12:  prefix = "Good morning"
        case 12..<17: prefix = "Good afternoon"
        case 17..<22: prefix = "Good evening"
        default:      prefix = "Good night"
        }
        return name.isEmpty ? "\(prefix)!" : "\(prefix), \(name)!"
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("[TasksVM] Failed to save context: \(error)")
        }
    }

    // MARK: - Server Sync

    private func syncFromServer() async {
        do {
            let response: TaskListResponse = try await APIClient.shared.get(APIEndpoints.tasks)
            for dto in response.data {
                mergeFromServer(dto)
            }
            saveContext()
            fetchLocal()
        } catch {
            print("[TasksVM] Sync pull failed: \(error)")
        }
    }

    private func mergeFromServer(_ dto: TaskDTO) {
        guard let id = dto.id else { return }

        // Check if we already have this task locally
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.supabaseId == id }
        )

        let existing = try? modelContext.fetch(descriptor).first

        if let existing {
            // Server wins if local isn't pending changes
            if existing.syncStatus == .synced {
                existing.title = dto.title
                existing.note = dto.note ?? ""
                existing.isCompleted = dto.isCompleted
                existing.priority = TaskItem.Priority(rawValue: dto.priority) ?? .medium
                existing.dueDate = dto.dueDate
                existing.completedAt = dto.completedAt
                existing.updatedAt = dto.updatedAt ?? Date()
            }
        } else {
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
            modelContext.insert(task)
        }
    }

    private func pushTask(_ task: TaskItem) async {
        struct CreateBody: Encodable {
            let title: String
            let note: String
            let is_completed: Bool
            let priority: String
            let due_date: String?
            let completed_at: String?
        }

        let body = CreateBody(
            title: task.title,
            note: task.note,
            is_completed: task.isCompleted,
            priority: task.priority.rawValue,
            due_date: task.dueDate.map { ISO8601DateFormatter().string(from: $0) },
            completed_at: task.completedAt.map { ISO8601DateFormatter().string(from: $0) }
        )

        do {
            let response: TaskResponse = try await APIClient.shared.post(APIEndpoints.tasks, body: body)
            task.supabaseId = response.data.id
            task.syncStatus = .synced
            saveContext()
        } catch {
            print("[TasksVM] Push task failed: \(error)")
        }
    }

    private func updateTaskOnServer(_ task: TaskItem) async {
        guard let id = task.supabaseId else { return }

        struct UpdateBody: Encodable {
            let title: String
            let note: String
            let is_completed: Bool
            let priority: String
            let due_date: String?
            let completed_at: String?
        }

        let body = UpdateBody(
            title: task.title,
            note: task.note,
            is_completed: task.isCompleted,
            priority: task.priority.rawValue,
            due_date: task.dueDate.map { ISO8601DateFormatter().string(from: $0) },
            completed_at: task.completedAt.map { ISO8601DateFormatter().string(from: $0) }
        )

        do {
            let _: TaskResponse = try await APIClient.shared.put(APIEndpoints.task(id), body: body)
            task.syncStatus = .synced
            saveContext()
        } catch {
            print("[TasksVM] Update task failed: \(error)")
        }
    }

    private func deleteTaskOnServer(_ id: String) async {
        do {
            struct DeleteResponse: Decodable {
                let ok: Bool
                let data: DeleteData
                struct DeleteData: Decodable { let deleted: Bool }
            }
            let _: DeleteResponse = try await APIClient.shared.delete(APIEndpoints.task(id))
        } catch {
            print("[TasksVM] Delete task on server failed: \(error)")
        }
    }
}
