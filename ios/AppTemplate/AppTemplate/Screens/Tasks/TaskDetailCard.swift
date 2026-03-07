import SwiftUI

// MARK: - TaskDetailCard
// Single task row matching the Stitch today-list visual direction.

struct TaskDetailCard: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(task.isCompleted ? Color.success : Color.accent.opacity(0.35))
                    .animation(.snappy, value: task.isCompleted)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    Text(task.title)
                        .font(.body(16, weight: .bold))
                        .foregroundStyle(task.isCompleted ? Color.textSecondary : Color.textPrimary)
                        .strikethrough(task.isCompleted, color: Color.textTertiary)
                        .lineLimit(2)

                    Spacer(minLength: 0)
                }

                if !task.note.isEmpty {
                    Text(task.note)
                        .font(.body(13))
                        .foregroundStyle(task.isCompleted ? Color.textTertiary : Color.textSecondary)
                        .lineLimit(2)
                }

                HStack(spacing: Spacing.sm) {
                    if let dueDate = task.dueDate {
                        Label(timeString(dueDate), systemImage: "clock")
                            .font(.body(11, weight: .medium))
                            .foregroundStyle(isOverdue(dueDate) ? Color.danger : Color.textSecondary)
                    } else {
                        Label("Any time", systemImage: "sparkles")
                            .font(.body(11, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                    }

                    priorityBadge
                }
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

    private var priorityBadge: some View {
        Text(task.priority.label)
            .font(.body(11, weight: .bold))
            .textCase(.uppercase)
            .foregroundStyle(priorityColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(priorityColor.opacity(0.12))
            .clipShape(Capsule())
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low:
            return Color.warning
        case .medium:
            return Color.accent
        case .high:
            return Color.danger
        }
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func isOverdue(_ date: Date) -> Bool {
        !task.isCompleted && date < Date()
    }
}
