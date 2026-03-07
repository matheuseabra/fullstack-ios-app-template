import SwiftUI

// MARK: - DashboardView
// Today task list matching the Stitch reference.

struct DashboardView: View {
    @ObservedObject var vm: TasksViewModel
    @Binding var isTabBarVisible: Bool
    @State private var selectedTask: TaskItem?
    @State private var showTaskDetail = false
    @State private var showPaywall = false

    init(vm: TasksViewModel, isTabBarVisible: Binding<Bool> = .constant(true)) {
        self._vm = ObservedObject(wrappedValue: vm)
        self._isTabBarVisible = isTabBarVisible
    }

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
            .drawer(isPresented: $showPaywall, detents: [.large]) {
                PaywallFlowView {
                    showPaywall = false
                }
            }
            .onChange(of: showTaskDetail) { _, newValue in
                isTabBarVisible = !newValue
            }
            .onChange(of: showPaywall) { _, newValue in
                isTabBarVisible = !newValue
            }
            .onAppear {
                isTabBarVisible = true
                Analytics.track(.featureUsed(name: "today"))
            }
        }
    }

    private var header: some View {
        HStack {
            if !PaymentManager.shared.hasProAccess {
                Button {
                    HapticManager.medium()
                    showPaywall = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12, weight: .bold))

                        Text("Upgrade")
                            .font(.body(13, weight: .bold))
                    }
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, 9)
                    .background(Color.bgElevated)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.border.opacity(0.75), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Text(todayDateText)
                .font(.body(12, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            if vm.activeTasksForSelectedDate.isEmpty {
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
                VStack(spacing: 0) {
                    ForEach(Array(vm.activeTasksForSelectedDate.enumerated()), id: \.element.id) { index, task in
                        HStack(alignment: .top, spacing: Spacing.md) {
                            Text(createdTimeString(for: task))
                                .font(.body(11, weight: .bold))
                                .foregroundStyle(Color.textSecondary)
                                .frame(width: 44, alignment: .trailing)
                                .padding(.top, Spacing.lg)

                            TaskDetailCard(task: task) {
                                vm.toggleComplete(task)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTask = task
                            showTaskDetail = true
                        }

                        if index < vm.activeTasksForSelectedDate.count - 1 {
                            DottedDivider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.snappy, value: vm.activeTasksForSelectedDate.count)
    }

    private var todayDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: vm.selectedDate)
    }

    private var emptyStateTitle: String {
        Calendar.current.isDateInToday(vm.selectedDate) ? "You have nothing scheduled for today." : "Nothing scheduled for this day."
    }

    private var emptyStateSubtitle: String {
        Calendar.current.isDateInToday(vm.selectedDate) ? "Have a good \(vm.dayPartGreeting)." : "Pick another day or add a task."
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
