import SwiftUI

// MARK: - DashboardView
// Today task list matching the Stitch reference.

struct DashboardView: View {
    @ObservedObject var vm: TasksViewModel
    @State private var selectedTask: TaskItem?
    @State private var showTaskDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()

                Group {
                    if vm.isLoading && vm.tasks.isEmpty {
                        loadingSkeleton
                    } else if let error = vm.errorMessage, vm.tasks.isEmpty {
                        EmptyStateView(
                            icon: "wifi.slash",
                            title: "Couldn't load",
                            subtitle: error,
                            action: ("Retry", { Task { await vm.reload() } })
                        )
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: Spacing.xl) {
                                header
                                tasksSection
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.lg)
                            .padding(.bottom, 120)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showTaskDetail) {
                if let selectedTask {
                    TaskDetailView(vm: vm, task: selectedTask)
                }
            }
            .onAppear { Analytics.track(.featureUsed(name: "today")) }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(spacing: Spacing.sm) {
                Text("Today")
                    .font(.display(38, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Circle()
                    .fill(Color.danger)
                    .frame(width: 10, height: 10)
                    .offset(y: -6)
            }

            Spacer()

            Text(todayDateText)
                .font(.body(13, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            if groupedTodayTasks.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "checklist")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundStyle(Color.textTertiary)
                    Text("No tasks for today")
                        .font(.body(15))
                        .foregroundStyle(Color.textSecondary)
                    Text("Tap + to add one")
                        .font(.body(13))
                        .foregroundStyle(Color.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xxxl)
            } else {
                ForEach(Array(groupedTodayTasks.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(section.title)
                            .font(.body(12, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(Color.textSecondary)

                        VStack(spacing: Spacing.md) {
                            ForEach(section.tasks, id: \.id) { task in
                                TaskDetailCard(task: task) {
                                    vm.toggleComplete(task)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTask = task
                                    showTaskDetail = true
                                }
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.snappy, value: vm.tasksForSelectedDate.count)
    }

    private var groupedTodayTasks: [(title: String, tasks: [TaskItem])] {
        let sortedTasks = vm.todayTasks.sorted { lhs, rhs in
            switch (lhs.dueDate, rhs.dueDate) {
            case let (left?, right?):
                return left < right
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhs.createdAt < rhs.createdAt
            }
        }

        let grouped = Dictionary(grouping: sortedTasks) { task -> String in
            guard let dueDate = task.dueDate else { return "Any Time" }
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: dueDate)
        }

        return grouped.keys.sorted { lhs, rhs in
            if lhs == "Any Time" { return false }
            if rhs == "Any Time" { return true }
            return lhs < rhs
        }.map { key in
            (title: key, tasks: grouped[key] ?? [])
        }
    }

    private var todayDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: Date())
    }

    private var loadingSkeleton: some View {
        VStack(spacing: Spacing.md) {
            SkeletonView(style: .row)
            SkeletonView(style: .row)
            SkeletonView(style: .row)
            SkeletonView(style: .row)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
    }
}
