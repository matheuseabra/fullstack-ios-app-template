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
                                WeekCalendarStrip(selectedDate: $vm.selectedDate, tasks: vm.tasks)
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
        HStack {
            Spacer()

            Text(todayDateText)
                .font(.body(12, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            if orderedVisibleTasks.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "checklist")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundStyle(Color.textTertiary)
                    Text(emptyStateTitle)
                        .font(.body(15))
                        .foregroundStyle(Color.textSecondary)
                    Text(emptyStateSubtitle)
                        .font(.body(13))
                        .foregroundStyle(Color.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xxxl)
            } else {
                VStack(spacing: Spacing.md) {
                    ForEach(orderedVisibleTasks, id: \.id) { task in
                        HStack(alignment: .top, spacing: Spacing.md) {
                            Text(createdTimeString(for: task))
                                .font(.body(11, weight: .bold))
                                .foregroundStyle(Color.textSecondary)
                                .frame(width: 44, alignment: .trailing)
                                .padding(.top, Spacing.md)

                            TaskDetailCard(task: task) {
                                vm.toggleComplete(task)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTask = task
                            showTaskDetail = true
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.snappy, value: orderedVisibleTasks.count)
    }

    private var orderedVisibleTasks: [TaskItem] {
        vm.tasksForSelectedDate.sorted { lhs, rhs in
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
    }

    private var todayDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: vm.selectedDate)
    }

    private var emptyStateTitle: String {
        Calendar.current.isDateInToday(vm.selectedDate) ? "No tasks for today" : "No tasks for this day"
    }

    private var emptyStateSubtitle: String {
        Calendar.current.isDateInToday(vm.selectedDate) ? "Tap + to add one" : "Tap + to add one for this day"
    }

    private func createdTimeString(for task: TaskItem) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: task.createdAt)
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
