import SwiftUI

// MARK: - TaskListView
// Calendar timeline view for the selected date.

struct TaskListView: View {
    @ObservedObject var vm: TasksViewModel
    @State private var selectedTask: TaskItem?
    @State private var showTaskDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        header

                        WeekCalendarStrip(selectedDate: $vm.selectedDate)

                        if timelineTasks.isEmpty {
                            emptyState
                                .padding(.top, Spacing.xxxl)
                        } else {
                            VStack(alignment: .leading, spacing: Spacing.lg) {
                                Text(selectedDateLabel)
                                    .font(.body(14, weight: .semibold))
                                    .foregroundStyle(Color.textSecondary)

                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.border.opacity(0.7))
                                        .frame(width: 1)
                                        .padding(.leading, 52)

                                    VStack(spacing: Spacing.lg) {
                                        ForEach(timelineTasks, id: \.id) { task in
                                            timelineRow(task)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, 120)
                }
            }
            .navigationDestination(isPresented: $showTaskDetail) {
                if let selectedTask {
                    TaskDetailView(vm: vm, task: selectedTask)
                }
            }
            .onAppear { Analytics.track(.featureUsed(name: "calendar")) }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(spacing: Spacing.sm) {
                Text("Today")
                    .font(.display(32, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Circle()
                    .fill(Color.danger)
                    .frame(width: 10, height: 10)
                    .offset(y: -5)
            }

            Spacer()

            Text(fullDateText)
                .font(.body(13, weight: .medium))
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var timelineTasks: [TaskItem] {
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

    private var selectedDateLabel: String {
        if Calendar.current.isDateInToday(vm.selectedDate) {
            return "Your schedule for today"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: vm.selectedDate)
    }

    private var fullDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: vm.selectedDate)
    }

    private func timelineRow(_ task: TaskItem) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .trailing, spacing: 0) {
                Text(timeLabel(for: task))
                    .font(.body(11, weight: .bold))
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(width: 40)
            .padding(.top, Spacing.md)

            HStack(alignment: .top, spacing: Spacing.md) {
                Button {
                    vm.toggleComplete(task)
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(task.isCompleted ? Color.success : Color.textTertiary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.body(16, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.leading)
                        .strikethrough(task.isCompleted, color: Color.textTertiary)

                    if !task.note.isEmpty {
                        Text(task.note)
                            .font(.body(13))
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    HStack(spacing: Spacing.md) {
                        timelineChip(systemName: "flag.fill", label: task.priority.label, color: priorityColor(for: task.priority))

                        if task.isCompleted {
                            timelineChip(systemName: "checkmark.circle.fill", label: "Done", color: Color.success)
                        } else if let dueDate = task.dueDate {
                            timelineChip(systemName: "clock", label: shortTimeString(dueDate), color: isOverdue(dueDate, task: task) ? Color.danger : Color.textSecondary)
                        } else {
                            timelineChip(systemName: "sparkles", label: "Any time", color: Color.textSecondary)
                        }
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(Spacing.lg)
            .background(Color.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xl)
                    .stroke(Color.border.opacity(0.75), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: Radius.xl))
            .onTapGesture {
                selectedTask = task
                showTaskDetail = true
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "calendar.badge.clock",
            title: "Nothing scheduled",
            subtitle: "Add a task for this date or pick another day in the week strip."
        )
    }

    private func timelineChip(systemName: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .bold))
            Text(label)
                .font(.body(10, weight: .bold))
                .textCase(.uppercase)
        }
        .foregroundStyle(color)
    }

    private func priorityColor(for priority: TaskItem.Priority) -> Color {
        switch priority {
        case .low:
            return Color.textSecondary
        case .medium:
            return Color.accent
        case .high:
            return Color.danger
        }
    }

    private func timeLabel(for task: TaskItem) -> String {
        guard let dueDate = task.dueDate else { return "Any" }
        return shortTimeString(dueDate)
    }

    private func shortTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func isOverdue(_ date: Date, task: TaskItem) -> Bool {
        !task.isCompleted && date < Date()
    }
}
