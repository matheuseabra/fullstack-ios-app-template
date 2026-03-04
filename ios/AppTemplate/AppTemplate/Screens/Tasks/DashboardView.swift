import SwiftUI

// MARK: - DashboardView
// Calendar strip, summary card, and task cards for the selected day.

struct DashboardView: View {
    @ObservedObject var vm: TasksViewModel
    @Binding var showSettings: Bool
    @State private var showUpgrade = false

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
                            VStack(spacing: Spacing.xl) {
                                // Week calendar strip
                                WeekCalendarStrip(selectedDate: $vm.selectedDate)
                                    .padding(.top, Spacing.xs)

                                // Summary card
                                TaskSummaryCard(
                                    completed: vm.completedToday,
                                    total: vm.totalToday,
                                    rate: vm.completionRate
                                )

                                // Task cards centered
                                tasksSection
                            }
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // Show upgrade only when user is NOT on a paid plan
                    if vm.subscription == nil || vm.subscription?.isActive == false {
                        Button {
                            showUpgrade = true
                            HapticManager.light()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.up.circle.fill")
                                Text("Upgrade")
                                    .font(.body(14, weight: .semibold))
                            }
                            .foregroundStyle(Color.accent)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showUpgrade) {
                PaywallFlowView()
            }
        }
    }

    // MARK: - Tasks Section

    private var tasksSection: some View {
        VStack(spacing: Spacing.md) {
            let dateTasks = vm.tasksForSelectedDate

            // Section header
            HStack {
                Text(formattedDate)
                    .font(.body(14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Text("\(dateTasks.filter(\.isCompleted).count)/\(dateTasks.count)")
                    .font(.mono(13))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, Spacing.lg)

            if dateTasks.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "checklist")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundStyle(Color.textTertiary)
                    Text("No tasks for this day")
                        .font(.body(15))
                        .foregroundStyle(Color.textSecondary)
                    Text("Tap + to add one")
                        .font(.body(13))
                        .foregroundStyle(Color.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xxxl)
            } else {
                ForEach(dateTasks, id: \.id) { task in
                    TaskDetailCard(task: task) {
                        vm.toggleComplete(task)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
                }
            }
        }
        .animation(.snappy, value: vm.tasksForSelectedDate.count)
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
