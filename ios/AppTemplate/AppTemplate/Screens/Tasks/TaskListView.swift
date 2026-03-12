import SwiftUI

// MARK: - TaskListView
// Month history view for browsing task activity.

struct TaskListView: View {
    @ObservedObject var vm: TasksViewModel
    @Binding var isTabBarVisible: Bool
    @State private var displayedMonth: Date
    @State private var showDaySheet = false
    @State private var monthTransitionDirection = 1

    init(vm: TasksViewModel, isTabBarVisible: Binding<Bool> = .constant(true)) {
        self._vm = ObservedObject(wrappedValue: vm)
        self._isTabBarVisible = isTabBarVisible
        self._displayedMonth = State(initialValue: Calendar.current.dateInterval(of: .month, for: vm.selectedDate)?.start ?? vm.selectedDate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        header
                        monthNavigator
                        ZStack {
                            monthPage
                                .id(displayedMonth)
                                .transition(monthTransition)
                        }
                        .clipped()
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                .simultaneousGesture(monthSwipeGesture)
                .animation(.easeInOut(duration: 0.24), value: displayedMonth)
            }
            .drawer(isPresented: $showDaySheet, detents: [.medium, .large]) {
                DayHistorySheet(vm: vm, selectedDate: vm.selectedDate) {
                    showDaySheet = false
                }
            }
            .onChange(of: vm.selectedDate) { _, newValue in
                let nextMonth = Calendar.current.dateInterval(of: .month, for: newValue)?.start ?? newValue
                if !Calendar.current.isDate(nextMonth, equalTo: displayedMonth, toGranularity: .month) {
                    monthTransitionDirection = nextMonth >= displayedMonth ? 1 : -1
                    displayedMonth = nextMonth
                }
            }
            .onChange(of: showDaySheet) { _, newValue in
                isTabBarVisible = !newValue
            }
            .onAppear {
                isTabBarVisible = true
                displayedMonth = Calendar.current.dateInterval(of: .month, for: vm.selectedDate)?.start ?? vm.selectedDate
                Analytics.screen("Calendar")
            }
        }
    }

    private var monthPage: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            monthSummary
            weekdayHeader
            monthGrid
        }
    }

    private var monthSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height),
                      abs(value.translation.width) > 44 else {
                    return
                }

                shiftMonth(by: value.translation.width < 0 ? 1 : -1)
                HapticManager.selection()
            }
    }

    private var monthTransition: AnyTransition {
        if monthTransitionDirection >= 0 {
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

    private var header: some View {
        HStack(alignment: .center) {
            Text("Calendar")
                .font(.display(32, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Text(monthTitle)
                .font(.body(13, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var monthNavigator: some View {
        HStack(spacing: Spacing.md) {
            monthControlButton(systemName: "chevron.left", label: "Previous Month") {
                shiftMonth(by: -1)
            }

            Spacer()

            VStack(spacing: 3) {
                Text(monthTitle)
                    .font(.display(24, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(monthSubtitle)
                    .font(.body(12, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            monthControlButton(systemName: "chevron.right", label: "Next Month") {
                shiftMonth(by: 1)
            }
        }
    }

    private func monthControlButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(label, systemImage: systemName, action: action)
            .labelStyle(.iconOnly)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color.textPrimary)
            .frame(width: 40, height: 40)
            .background(Color.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(Color.border.opacity(0.7), lineWidth: 1)
            )
            .buttonStyle(.plain)
    }

    private var monthSummary: some View {
        HStack(spacing: Spacing.sm) {
            summaryPill(label: "Open", value: monthPendingCount, color: Color.textPrimary)
            summaryPill(label: "Done", value: monthCompletedCount, color: Color.success)
            Spacer(minLength: 0)
        }
    }

    private func summaryPill(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(color)
                .frame(width: 10, height: 10)

            Text("\(value) \(label)")
                .font(.body(12, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 8)
        .background(Color.bgElevated)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.border.opacity(0.7), lineWidth: 1)
        )
    }

    private var weekdayHeader: some View {
        let symbols = reorderedWeekdaySymbols

        return LazyVGrid(columns: monthColumns, spacing: Spacing.sm) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol.uppercased())
                    .font(.body(10, weight: .bold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        LazyVGrid(columns: monthColumns, spacing: Spacing.sm) {
            ForEach(monthDays) { item in
                if let date = item.date {
                    dayCell(for: date)
                } else {
                    Color.clear
                        .frame(height: 52)
                }
            }
        }
    }

    private func dayCell(for date: Date) -> some View {
        let summary = monthSummaries[Calendar.current.startOfDay(for: date)] ?? .init(pendingCount: 0, completedCount: 0)
        let isSelected = Calendar.current.isDate(date, inSameDayAs: vm.selectedDate)
        let isToday = Calendar.current.isDateInToday(date)

        return Button {
            vm.selectedDate = date
            showDaySheet = true
            HapticManager.selection()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isToday {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 28, height: 28)
                    } else if isSelected {
                        Circle()
                            .stroke(Color.border, lineWidth: 1)
                            .frame(width: 28, height: 28)
                    }

                    Text(dayNumber(date))
                        .font(.body(15, weight: isToday || isSelected ? .bold : .semibold))
                        .foregroundStyle(isToday ? Color.white : Color.textPrimary)
                }
                .frame(height: 28)

                if summary.totalCount > 0 {
                    Circle()
                        .fill(dayIndicatorColor(summary: summary, isToday: isToday))
                        .frame(width: 5, height: 5)
                } else {
                    Color.clear
                        .frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(calendarDayIdentifier(for: date))
    }

    private var monthColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 7)
    }

    private var monthSummaries: [Date: TasksViewModel.DaySummary] {
        vm.monthSummaries(for: displayedMonth)
    }

    private var monthDays: [MonthDayItem] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let dayRange = calendar.range(of: .day, in: .month, for: monthInterval.start) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingSlots = (firstWeekday - calendar.firstWeekday + 7) % 7

        var days = Array(repeating: MonthDayItem(date: nil), count: leadingSlots)

        days += dayRange.compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset - 1, to: monthInterval.start) else {
                return nil
            }

            return MonthDayItem(date: date)
        }

        let remainder = days.count % 7
        if remainder != 0 {
            days += Array(repeating: MonthDayItem(date: nil), count: 7 - remainder)
        }

        return days
    }

    private var monthPendingCount: Int {
        monthSummaries.values.reduce(0) { $0 + $1.pendingCount }
    }

    private var monthCompletedCount: Int {
        monthSummaries.values.reduce(0) { $0 + $1.completedCount }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var monthSubtitle: String {
        "Tap a day to view history"
    }

    private var reorderedWeekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let startIndex = max(calendar.firstWeekday - 1, 0)

        return Array(symbols[startIndex...] + symbols[..<startIndex])
    }

    private func shiftMonth(by value: Int) {
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) else {
            return
        }

        monthTransitionDirection = value
        withAnimation(.snappy(duration: 0.22)) {
            displayedMonth = Calendar.current.dateInterval(of: .month, for: nextMonth)?.start ?? nextMonth
        }
    }

    private func dayNumber(_ date: Date) -> String {
        String(Calendar.current.component(.day, from: date))
    }

    private func dayIndicatorColor(summary: TasksViewModel.DaySummary, isToday: Bool) -> Color {
        if isToday {
            return Color.black
        }

        return summary.pendingCount > 0 ? Color.textPrimary : Color.success
    }

    private func calendarDayIdentifier(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "calendar.day.today"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "calendar.day.\(formatter.string(from: date))"
    }

    private struct MonthDayItem: Identifiable {
        let id = UUID()
        let date: Date?
    }
}

private struct DayHistorySheet: View {
    @ObservedObject var vm: TasksViewModel
    let selectedDate: Date
    let onClose: () -> Void

    @State private var selectedTask: TaskItem?
    @State private var showTaskDetail = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sheetTitle)
                            .font(.display(26, weight: .bold))
                            .foregroundStyle(Color.textPrimary)

                        Text(sheetSubtitle)
                            .font(.body(13, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer(minLength: 0)

                    Button("Close", systemImage: "xmark", action: onClose)
                        .labelStyle(.iconOnly)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(Color.bgSurface)
                        .clipShape(Circle())
                        .buttonStyle(.plain)
                }

                if dayTasks.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.exclamationmark",
                        title: "Nothing logged for this day",
                        subtitle: "Pick another date in the month or add a task from Home."
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.xl) {
                            if !pendingTasks.isEmpty {
                                taskSection(title: "Open", tasks: pendingTasks)
                            }

                            if !completedTasks.isEmpty {
                                taskSection(title: "Completed", tasks: completedTasks)
                            }
                        }
                        .padding(.bottom, Spacing.xxxl)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xl)
            .background(Color.bg.ignoresSafeArea())
            .navigationDestination(isPresented: $showTaskDetail) {
                if let selectedTask {
                    TaskDetailView(vm: vm, task: selectedTask)
                }
            }
        }
    }

    private var dayTasks: [TaskItem] {
        vm.historicalTasksForSelectedDate
    }

    private var pendingTasks: [TaskItem] {
        vm.activeTasksForSelectedDate
    }

    private var completedTasks: [TaskItem] {
        vm.completedTasksForSelectedDate
    }

    private var sheetTitle: String {
        selectedDate.formatted(.dateTime.weekday(.wide).month().day())
    }

    private var sheetSubtitle: String {
        let summary = vm.taskSummary(for: selectedDate)
        if summary.totalCount == 0 {
            return "No activity recorded"
        }

        return "\(summary.pendingCount) open · \(summary.completedCount) completed"
    }

    private func taskSection(title: String, tasks: [TaskItem]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.body(11, weight: .bold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Color.textSecondary)

            VStack(spacing: 0) {
                ForEach(tasks.enumerated(), id: \.element.id) { index, task in
                    Button {
                        selectedTask = task
                        showTaskDetail = true
                    } label: {
                        HStack(alignment: .top, spacing: Spacing.md) {
                            Text(historyTimeString(for: task))
                                .font(.body(11, weight: .bold))
                                .foregroundStyle(Color.textSecondary)
                                .frame(width: 50, alignment: .trailing)
                                .padding(.top, 15)

                            TaskDetailCard(task: task) {
                                vm.toggleComplete(task)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    if index < tasks.count - 1 {
                        DottedDivider()
                            .padding(.leading, 56)
                    }
                }
            }
        }
    }

    private func historyTimeString(for task: TaskItem) -> String {
        (task.dueDate ?? task.createdAt).formatted(.dateTime.hour().minute())
    }
}
