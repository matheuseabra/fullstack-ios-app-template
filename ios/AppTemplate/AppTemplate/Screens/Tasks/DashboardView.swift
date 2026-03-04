import SwiftUI

// MARK: - DashboardView
// Top-level dashboard showing greeting, calendar strip, summary card, and task list for selected date.

struct DashboardView: View {
    @ObservedObject var vm: TasksViewModel
    @Binding var showSettings: Bool

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
                                // Greeting + Pro badge
                                headerSection

                                // Week calendar strip
                                WeekCalendarStrip(selectedDate: $vm.selectedDate)

                                // Summary card
                                TaskSummaryCard(
                                    completed: vm.completedToday,
                                    total: vm.totalToday,
                                    rate: vm.completionRate
                                )

                                // Tasks for selected date
                                tasksSection
                            }
                            .padding(.bottom, 100) // Space for tab bar
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(vm.greeting)
                .font(.display(24))
                .foregroundStyle(Color.textPrimary)

            if let sub = vm.subscription, sub.isActive {
                Label("Pro", systemImage: "star.fill")
                    .font(.body(13, weight: .semibold))
                    .foregroundStyle(Color.accent)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }

    // MARK: - Tasks Section

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            let dateTasks = vm.tasksForSelectedDate

            if dateTasks.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "checklist")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundStyle(Color.textTertiary)
                    Text("No tasks for this day")
                        .font(.body(15))
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xxl)
            } else {
                Text("Tasks for \(formattedDate)")
                    .font(.body(14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, Spacing.lg)

                ForEach(dateTasks, id: \.id) { task in
                    TaskDetailCard(task: task) {
                        vm.toggleComplete(task)
                    }
                    .padding(.horizontal, Spacing.lg)
                }
            }
        }
    }

    private var formattedDate: String {
        if Calendar.current.isDateInToday(vm.selectedDate) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(vm.selectedDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: vm.selectedDate)
        }
    }

    // MARK: - Loading Skeleton

    private var loadingSkeleton: some View {
        VStack(spacing: Spacing.md) {
            SkeletonView(style: .row)
            SkeletonView(style: .card)
            SkeletonView(style: .row)
            SkeletonView(style: .card)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }
}
