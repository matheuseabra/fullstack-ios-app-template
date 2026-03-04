import SwiftUI

// MARK: - TaskListView
// Full task list with segmented filter (All / Pending / Completed).

struct TaskListView: View {
    @ObservedObject var vm: TasksViewModel
    @State private var filter: Filter = .all
    @State private var searchText = ""

    enum Filter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Completed"
    }

    private var filteredTasks: [TaskItem] {
        let base: [TaskItem]
        switch filter {
        case .all:       base = vm.tasks
        case .pending:   base = vm.pendingTasks
        case .completed: base = vm.completedTasks
        }

        if searchText.isEmpty { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
            || $0.note.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segmented filter
                    Picker("Filter", selection: $filter) {
                        ForEach(Filter.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)

                    if filteredTasks.isEmpty {
                        Spacer()
                        emptyState
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredTasks, id: \.id) { task in
                                TaskDetailCard(task: task) {
                                    vm.toggleComplete(task)
                                }
                                .listRowBackground(Color.bg)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(
                                    top: Spacing.xs,
                                    leading: Spacing.lg,
                                    bottom: Spacing.xs,
                                    trailing: Spacing.lg
                                ))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        vm.deleteTask(task)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        vm.toggleComplete(task)
                                    } label: {
                                        Label(
                                            task.isCompleted ? "Undo" : "Done",
                                            systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                        )
                                    }
                                    .tint(Color.success)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
                .padding(.bottom, 80) // Space for tab bar
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search tasks...")
        }
    }

    private var emptyState: some View {
        Group {
            switch filter {
            case .all:
                EmptyStateView(
                    icon: "checklist",
                    title: "No tasks yet",
                    subtitle: "Tap the + button to create your first task."
                )
            case .pending:
                EmptyStateView(
                    icon: "party.popper",
                    title: "All caught up!",
                    subtitle: "No pending tasks. Great job!"
                )
            case .completed:
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "Nothing completed yet",
                    subtitle: "Complete a task and it will appear here."
                )
            }
        }
    }
}
