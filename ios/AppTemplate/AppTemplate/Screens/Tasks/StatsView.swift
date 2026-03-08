import SwiftUI

// MARK: - StatsView
// Productivity dashboard derived from local task data.

struct StatsView: View {
    @ObservedObject var vm: TasksViewModel

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        header
                        weeklyProgressCard
                        overviewSection
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, 120)
                }
            }
            .navigationBarHidden(true)
            .onAppear { Analytics.screen("Stats") }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(spacing: Spacing.sm) {
                Text("Stats")
                    .font(.display(38, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Circle()
                    .fill(Color.accent)
                    .frame(width: 10, height: 10)
                    .offset(y: -6)
            }

            Spacer()

            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 38, height: 38)
                .background(Color.bgElevated)
                .clipShape(Circle())
        }
    }

    private var weeklyProgressCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Weekly Progress")
                        .font(.body(11, weight: .bold))
                        .tracking(1.5)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.textSecondary)

                    Text("\(weeklyCompletedCount) Tasks Done")
                        .font(.display(28, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                }

                Spacer()

                Text(weeklyChangeText)
                    .font(.body(12, weight: .bold))
                    .foregroundStyle(Color.success)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 6)
                    .background(Color.success.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            }

            HStack(alignment: .bottom, spacing: Spacing.sm) {
                ForEach(weeklyBars, id: \.label) { item in
                    VStack(spacing: Spacing.sm) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.isToday ? Color.accent : Color.accent.opacity(0.22))
                            .frame(height: max(12, item.height))

                        Text(item.label)
                            .font(.body(10, weight: .bold))
                            .textCase(.uppercase)
                            .foregroundStyle(item.isToday ? Color.textPrimary : Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 148, alignment: .bottom)
        }
        .padding(Spacing.xl)
        .background(Color.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.border.opacity(0.65), lineWidth: 1)
        )
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Overview")
                .font(.body(13, weight: .bold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Color.textSecondary)

            StatsOverviewCard(
                icon: "flame.fill",
                iconColor: Color.warning,
                title: "Current Streak",
                subtitle: "Personal best is based on consecutive completion days",
                value: "\(currentStreak)",
                suffix: currentStreak == 1 ? "day" : "days"
            )

            StatsOverviewCard(
                icon: "checkmark.circle.fill",
                iconColor: Color.accent,
                title: "Completion Rate",
                subtitle: "Based on tasks scheduled this week",
                value: "\(weeklyCompletionRate)",
                suffix: "%"
            )

            StatsOverviewCard(
                icon: "exclamationmark.circle.fill",
                iconColor: Color.danger,
                title: "Overdue Tasks",
                subtitle: overdueTasksCount == 0 ? "Nothing overdue right now" : "Tasks that are past their due date",
                value: "\(overdueTasksCount)",
                suffix: overdueTasksCount == 1 ? "task" : "tasks"
            )
        }
    }

    private var completedTasksByDay: [(date: Date, count: Int)] {
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return nil
            }

            let count = vm.tasks.filter { task in
                guard let completedAt = task.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: date)
            }.count

            return (date: date, count: count)
        }
    }

    private var weeklyBars: [(label: String, height: CGFloat, isToday: Bool)] {
        let maxCount = max(completedTasksByDay.map(\.count).max() ?? 0, 1)

        return completedTasksByDay.map { item in
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            let label = String(formatter.string(from: item.date).prefix(3))
            let normalized = CGFloat(item.count) / CGFloat(maxCount)
            return (
                label: label,
                height: 24 + (normalized * 84),
                isToday: calendar.isDateInToday(item.date)
            )
        }
    }

    private var weeklyCompletedCount: Int {
        completedTasksByDay.map(\.count).reduce(0, +)
    }

    private var weeklyScheduledCount: Int {
        let today = calendar.startOfDay(for: Date())
        guard
            let start = calendar.date(byAdding: .day, value: -6, to: today),
            let end = calendar.date(byAdding: .day, value: 1, to: today)
        else {
            return vm.tasks.count
        }

        return vm.tasks.filter { task in
            let comparisonDate = task.dueDate ?? task.createdAt
            return comparisonDate >= start && comparisonDate < end
        }.count
    }

    private var weeklyCompletionRate: Int {
        guard weeklyScheduledCount > 0 else { return 0 }
        return Int((Double(weeklyCompletedCount) / Double(weeklyScheduledCount)) * 100)
    }

    private var overdueTasksCount: Int {
        vm.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < Date()
        }.count
    }

    private var currentStreak: Int {
        var streak = 0
        var cursor = calendar.startOfDay(for: Date())

        while vm.tasks.contains(where: { task in
            guard let completedAt = task.completedAt else { return false }
            return calendar.isDate(completedAt, inSameDayAs: cursor)
        }) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }

        return streak
    }

    private var weeklyChangeText: String {
        let priorWindow = previousWeeklyCompletedCount
        guard priorWindow > 0 else { return "+100%" }
        let delta = Double(weeklyCompletedCount - priorWindow) / Double(priorWindow)
        let percentage = Int(delta * 100)
        return percentage >= 0 ? "+\(percentage)%" : "\(percentage)%"
    }

    private var previousWeeklyCompletedCount: Int {
        let today = calendar.startOfDay(for: Date())
        guard
            let end = calendar.date(byAdding: .day, value: -7, to: today),
            let start = calendar.date(byAdding: .day, value: -13, to: today)
        else {
            return 0
        }

        return vm.tasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return completedAt >= start && completedAt < end
        }.count
    }
}

private struct StatsOverviewCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let value: String
    let suffix: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body(16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.body(12))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 0) {
                Text(value)
                    .font(.display(26, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(suffix)
                    .font(.body(11, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(Spacing.lg)
        .background(Color.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xl)
                .stroke(Color.border.opacity(0.65), lineWidth: 1)
        )
    }
}