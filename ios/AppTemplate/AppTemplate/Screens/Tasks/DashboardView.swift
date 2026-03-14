import SwiftUI

// MARK: - DashboardView
// Today task list matching the Stitch reference.

struct DashboardView: View {
    @ObservedObject var vm: TasksViewModel
    @Binding var isTabBarVisible: Bool
    @State private var selectedTask: TaskItem?
    @State private var showTaskDetail = false
    @State private var showPaywall = false
    @State private var dayTransitionDirection = 1

    private let calendar = Calendar.current

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
                        ScrollView {
                            VStack(alignment: .leading, spacing: Spacing.xl) {
                                header
                                    .padding(.horizontal, Spacing.lg)
                                WeekCalendarStrip(selectedDate: $vm.selectedDate, tasks: vm.tasks)
                                ZStack {
                                    tasksSection
                                        .id(Calendar.current.startOfDay(for: vm.selectedDate))
                                        .transition(dayTransition)
                                }
                                .padding(.horizontal, Spacing.lg)
                                .clipped()
                                .animation(.easeInOut(duration: 0.24), value: vm.selectedDate)
                            }
                            .padding(.top, Spacing.lg)
                            .padding(.bottom, 120)
                        }
                        .scrollIndicators(.hidden)
                        .simultaneousGesture(daySwipeGesture)
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
                Analytics.screen("Today")
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(headerTitle)
                    .font(.display(34, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(todayDateText)
                    .font(.body(12, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            if !PaymentManager.shared.hasProAccess {
                Button {
                    HapticManager.medium()
                    showPaywall = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12, weight: .bold))

                        Text("Pro")
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
                .padding(.top, 4)
            }
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            if vm.activeTasksForSelectedDate.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image("tasks_cleared_for_today")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 220)
                        .padding(.bottom, Spacing.xs)
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
                            Text(taskTimeString(for: task))
                                .font(.body(11, weight: .bold))
                                .foregroundStyle(Color.textSecondary)
                                .frame(width: 50, alignment: .trailing)
                                .padding(.top, 15)

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
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .contentShape(Rectangle())
        .animation(.snappy, value: vm.activeTasksForSelectedDate.count)
    }

    private var dayTransition: AnyTransition {
        if dayTransitionDirection >= 0 {
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        }

        return .asymmetric(
            insertion: .move(edge: .leading),
            removal: .move(edge: .trailing)
        )
    }

    private var daySwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height),
                      abs(value.translation.width) > 44 else {
                    return
                }

                shiftDay(by: value.translation.width < 0 ? 1 : -1)
            }
    }

    private var headerTitle: String {
        if calendar.isDateInToday(vm.selectedDate) {
            return "Today"
        }

        if calendar.isDateInTomorrow(vm.selectedDate) {
            return "Tomorrow"
        }

        if calendar.isDateInYesterday(vm.selectedDate) {
            return "Yesterday"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: vm.selectedDate)
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

    private func taskTimeString(for task: TaskItem) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: task.dueDate ?? task.createdAt)
    }

    private func shiftDay(by value: Int) {
        guard let nextDate = calendar.date(byAdding: .day, value: value, to: vm.selectedDate) else {
            return
        }

        dayTransitionDirection = value
        withAnimation(.easeInOut(duration: 0.24)) {
            vm.selectedDate = nextDate
        }
        HapticManager.selection()
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
