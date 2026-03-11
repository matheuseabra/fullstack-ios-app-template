import Foundation
import SwiftData
import SwiftUI
import os

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
    @Published var categories: [TaskCategory] = TaskCategory.defaults
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AppTemplate", category: "TasksVM")

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
        categories = TaskCategory.defaults

        // Fetch user + subscription from API
        if AppEnvironment.useLiveBackend {
            async let userFetch: UserResponse = APIClient.shared.get(APIEndpoints.me)
            async let subFetch: SubscriptionResponse = APIClient.shared.get(APIEndpoints.subscription)

            do {
                let (userResp, subResp) = try await (userFetch, subFetch)
                user = userResp.data
                subscription = subResp.data
            } catch is CancellationError {
                return
            } catch APIError.unauthorized {
                AppRouter.shared.signOut()
            } catch {
                errorMessage = error.localizedDescription
            }

            do {
                let categoryResp: TaskCategoryListResponse = try await APIClient.shared.get(APIEndpoints.taskCategories)
                categories = mergedCategories(with: categoryResp.data)
            } catch is CancellationError {
                return
            } catch {
                print("[TasksVM] Failed to fetch categories: \(error)")
            }

            // Pull remote tasks
            await syncFromServer()
        } else {
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
        }
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

    func category(with id: String?) -> TaskCategory? {
        guard let id else { return nil }
        return categories.first(where: { $0.id == id })
    }

    func createCategory(name: String, emoji: String) async -> TaskCategory? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedEmoji.isEmpty else {
            return nil
        }

        if !AppEnvironment.useLiveBackend {
            let category = TaskCategory.localCustom(name: trimmedName, emoji: trimmedEmoji)
            upsertCategory(category)
            return category
        }

        struct CreateBody: Encodable {
            let name: String
            let emoji: String
        }

        do {
            let response: TaskCategoryResponse = try await APIClient.shared.post(
                APIEndpoints.taskCategories,
                body: CreateBody(name: trimmedName, emoji: trimmedEmoji)
            )
            upsertCategory(response.data)
            return response.data
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func addTask(
        title: String,
        note: String = "",
        priority: TaskItem.Priority = .medium,
        dueDate: Date? = nil,
        category: TaskCategory? = nil,
        repeatFrequency: TaskItem.RepeatFrequency? = nil
    ) {
        let task = TaskItem(
            title: title,
            note: note,
            priority: priority,
            dueDate: dueDate,
            categoryId: category?.id,
            categoryName: category?.name,
            categoryEmoji: category?.emoji,
            repeatFrequency: repeatFrequency,
            seriesId: repeatFrequency == nil ? nil : UUID().uuidString
        )
        modelContext.insert(task)
        saveContext()
        fetchLocal()

        HapticManager.success()
        Analytics.track(.featureUsed(name: "task_created"))

        // Sync to server
        if AppEnvironment.useLiveBackend {
            Task { await pushTask(task) }
        }
    }

    func toggleComplete(_ task: TaskItem) {
        let isCompleting = !task.isCompleted
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date() : nil
        task.updatedAt = Date()
        task.syncStatus = .pendingUpdate

        #if DEBUG
        if !AppEnvironment.useLiveBackend, isCompleting, let nextTask = makeNextOccurrence(from: task) {
            modelContext.insert(nextTask)
        }
        #endif

        saveContext()
        fetchLocal()

        HapticManager.light()
        Analytics.track(.featureUsed(name: task.isCompleted ? "task_completed" : "task_uncompleted"))

        if AppEnvironment.useLiveBackend {
            Task { await updateTaskOnServer(task) }
        }
    }

    func deleteTask(_ task: TaskItem) {
        let supabaseId = task.supabaseId
        modelContext.delete(task)
        saveContext()
        fetchLocal()

        HapticManager.medium()
        Analytics.track(.featureUsed(name: "task_deleted"))

        if AppEnvironment.useLiveBackend, let id = supabaseId {
            Task { await deleteTaskOnServer(id) }
        }
    }

    func updateTask(
        _ task: TaskItem,
        title: String,
        note: String,
        priority: TaskItem.Priority,
        dueDate: Date?,
        category: TaskCategory?,
        repeatFrequency: TaskItem.RepeatFrequency?
    ) {
        task.title = title
        task.note = note
        task.priority = priority
        task.dueDate = dueDate
        task.categoryId = category?.id
        task.categoryName = category?.name
        task.categoryEmoji = category?.emoji
        task.repeatFrequency = repeatFrequency
        task.seriesId = repeatFrequency == nil ? nil : (task.seriesId ?? UUID().uuidString)
        task.updatedAt = Date()
        task.syncStatus = .pendingUpdate
        saveContext()
        fetchLocal()

        logger.info("Update task supabaseId: \(task.supabaseId ?? "nil", privacy: .public) syncStatus: \(String(describing: task.syncStatus), privacy: .public)")

        HapticManager.selection()
        Analytics.track(.featureUsed(name: "task_updated"))

        if AppEnvironment.useLiveBackend {
            Task { await updateTaskOnServer(task) }
        }
    }

    struct DaySummary {
        let pendingCount: Int
        let completedCount: Int

        var totalCount: Int {
            pendingCount + completedCount
        }
    }

    private enum TaskFilterScope {
        case active
        case completed
        case all
    }

    // MARK: - Derived Data

    var tasksForSelectedDate: [TaskItem] {
        filteredTasks(for: selectedDate, scope: .all)
    }

    var activeTasksForSelectedDate: [TaskItem] {
        filteredTasks(for: selectedDate, scope: .active)
    }

    var completedTasksForSelectedDate: [TaskItem] {
        filteredTasks(for: selectedDate, scope: .completed)
    }

    var historicalTasksForSelectedDate: [TaskItem] {
        historicalTasks(on: selectedDate)
            .sorted(by: sortTasks)
    }

    var todayTasks: [TaskItem] {
        tasksOccurring(on: Date())
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

    var dayPartGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<12:
            return "morning"
        case 12..<17:
            return "afternoon"
        case 17..<22:
            return "evening"
        default:
            return "night"
        }
    }

    var greeting: String {
        let name = user?.fullName?.components(separatedBy: " ").first ?? ""
        let prefix = "Good \(dayPartGreeting)"
        return name.isEmpty ? "\(prefix)!" : "\(prefix), \(name)!"
    }

    func taskSummary(for date: Date) -> DaySummary {
        let matchingTasks = historicalTasks(on: date)

        return DaySummary(
            pendingCount: matchingTasks.filter { !$0.isCompleted }.count,
            completedCount: matchingTasks.filter(\.isCompleted).count
        )
    }

    func monthSummaries(for month: Date) -> [Date: DaySummary] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let dayRange = calendar.range(of: .day, in: .month, for: monthInterval.start) else {
            return [:]
        }

        return dayRange.reduce(into: [Date: DaySummary]()) { summaries, day in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) else {
                return
            }

            let summary = taskSummary(for: date)
            if summary.totalCount > 0 {
                summaries[calendar.startOfDay(for: date)] = summary
            }
        }
    }

    // MARK: - Private

    private func filteredTasks(for date: Date, scope: TaskFilterScope) -> [TaskItem] {
        tasksOccurring(on: date)
            .filter { task in
                switch scope {
                case .active:
                    return !task.isCompleted
                case .completed:
                    return task.isCompleted
                case .all:
                    return true
                }
            }
            .sorted(by: sortTasks)
    }

    private func historicalTasks(on date: Date) -> [TaskItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        return tasks.filter { task in
            guard let dueDate = task.dueDate else {
                return false
            }

            return calendar.startOfDay(for: dueDate) == startOfDay
        }
    }

    private func tasksOccurring(on date: Date) -> [TaskItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        return tasks.filter { task in
            if let dueDate = task.dueDate {
                return calendar.startOfDay(for: dueDate) == startOfDay
            }

            return calendar.isDateInToday(startOfDay)
        }
    }

    private func sortTasks(_ lhs: TaskItem, _ rhs: TaskItem) -> Bool {
        if lhs.isCompleted != rhs.isCompleted {
            return !lhs.isCompleted && rhs.isCompleted
        }

        switch (lhs.dueDate, rhs.dueDate) {
        case let (left?, right?):
            if left != right {
                return left < right
            }
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            break
        }

        if lhs.isCompleted && rhs.isCompleted {
            return (lhs.completedAt ?? lhs.updatedAt) > (rhs.completedAt ?? rhs.updatedAt)
        }

        return lhs.createdAt < rhs.createdAt
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("[TasksVM] Failed to save context: \(error)")
        }
    }

    private func mergedCategories(with remote: [TaskCategory]) -> [TaskCategory] {
        var merged = Dictionary(uniqueKeysWithValues: TaskCategory.defaults.map { ($0.id, $0) })

        for category in remote {
            merged[category.id] = category
        }

        return merged.values.sorted { lhs, rhs in
            if lhs.isDefault != rhs.isDefault {
                return lhs.isDefault && !rhs.isDefault
            }

            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func upsertCategory(_ category: TaskCategory) {
        categories = mergedCategories(with: categories.filter { $0.id != category.id } + [category])
    }

    private func categoryFromDTO(_ dto: TaskDTO) -> TaskCategory? {
        guard let categoryId = dto.categoryId,
              let categoryName = dto.categoryName,
              let categoryEmoji = dto.categoryEmoji else {
            return nil
        }

        return TaskCategory(
            id: categoryId,
            userId: nil,
            name: categoryName,
            emoji: categoryEmoji,
            slug: dto.categorySlug,
            isDefault: dto.categoryIsDefault ?? false,
            createdAt: nil,
            updatedAt: nil
        )
    }

    private func apply(_ dto: TaskDTO, to task: TaskItem) {
        task.title = dto.title
        task.note = dto.note ?? ""
        task.isCompleted = dto.isCompleted
        task.priority = TaskItem.Priority(rawValue: dto.priority) ?? .medium
        task.dueDate = dto.dueDate
        task.completedAt = dto.completedAt
        task.categoryId = dto.categoryId
        task.categoryName = dto.categoryName
        task.categoryEmoji = dto.categoryEmoji
        task.repeatFrequency = dto.repeatFrequency
        task.seriesId = dto.seriesId
        task.createdAt = dto.createdAt ?? task.createdAt
        task.updatedAt = dto.updatedAt ?? Date()
        task.supabaseId = dto.id ?? task.supabaseId
    }

    private func nextDueDate(for task: TaskItem) -> Date? {
        guard let dueDate = task.dueDate,
              let repeatFrequency = task.repeatFrequency else {
            return nil
        }

        let calendar = Calendar.current

        switch repeatFrequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: dueDate)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: dueDate)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: dueDate)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: dueDate)
        }
    }

    private func makeNextOccurrence(from task: TaskItem) -> TaskItem? {
        guard let nextDueDate = nextDueDate(for: task),
              let seriesId = task.seriesId else {
            return nil
        }

        let duplicateExists = tasks.contains { candidate in
            candidate.seriesId == seriesId && candidate.dueDate == nextDueDate
        }

        if duplicateExists {
            return nil
        }

        return TaskItem(
            title: task.title,
            note: task.note,
            priority: task.priority,
            dueDate: nextDueDate,
            categoryId: task.categoryId,
            categoryName: task.categoryName,
            categoryEmoji: task.categoryEmoji,
            repeatFrequency: task.repeatFrequency,
            seriesId: seriesId
        )
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
        } catch is CancellationError {
            return
        } catch {
            print("[TasksVM] Sync pull failed: \(error)")
        }
    }

    private func mergeFromServer(_ dto: TaskDTO) {
        guard let id = dto.id else { return }
        if let category = categoryFromDTO(dto) {
            upsertCategory(category)
        }

        // Check if we already have this task locally
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.supabaseId == id }
        )

        let existing = try? modelContext.fetch(descriptor).first

        if let existing {
            // Server wins if local isn't pending changes
            if existing.syncStatus == .synced {
                apply(dto, to: existing)
            }
        } else {
            let task = TaskItem(
                title: dto.title,
                note: dto.note ?? "",
                isCompleted: dto.isCompleted,
                priority: TaskItem.Priority(rawValue: dto.priority) ?? .medium,
                dueDate: dto.dueDate,
                completedAt: dto.completedAt,
                categoryId: dto.categoryId,
                categoryName: dto.categoryName,
                categoryEmoji: dto.categoryEmoji,
                repeatFrequency: dto.repeatFrequency,
                seriesId: dto.seriesId,
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
            let category_id: String?
            let repeat_frequency: String?
        }

        let body = CreateBody(
            title: task.title,
            note: task.note,
            is_completed: task.isCompleted,
            priority: task.priority.rawValue,
            due_date: task.dueDate.map { ISO8601DateFormatter().string(from: $0) },
            completed_at: task.completedAt.map { ISO8601DateFormatter().string(from: $0) },
            category_id: task.categoryId,
            repeat_frequency: task.repeatFrequency?.rawValue
        )

        do {
            let response: TaskResponse = try await APIClient.shared.post(APIEndpoints.tasks, body: body)
            if let category = categoryFromDTO(response.data) {
                upsertCategory(category)
            }
            apply(response.data, to: task)
            task.syncStatus = .synced
            saveContext()
            fetchLocal()
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
            let category_id: String?
            let repeat_frequency: String?
        }

        let body = UpdateBody(
            title: task.title,
            note: task.note,
            is_completed: task.isCompleted,
            priority: task.priority.rawValue,
            due_date: task.dueDate.map { ISO8601DateFormatter().string(from: $0) },
            completed_at: task.completedAt.map { ISO8601DateFormatter().string(from: $0) },
            category_id: task.categoryId,
            repeat_frequency: task.repeatFrequency?.rawValue
        )

        do {
            let response: TaskMutationResponse = try await APIClient.shared.put(APIEndpoints.task(id), body: body)
            if let category = categoryFromDTO(response.data.task) {
                upsertCategory(category)
            }
            apply(response.data.task, to: task)
            task.syncStatus = .synced

            if let nextOccurrence = response.data.nextOccurrence {
                mergeFromServer(nextOccurrence)
            }

            saveContext()
            fetchLocal()
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
