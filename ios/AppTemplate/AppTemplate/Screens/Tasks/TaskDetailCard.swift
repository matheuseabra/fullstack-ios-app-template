import SwiftUI

// MARK: - TaskDetailCard
// Single task row with checkbox, title, priority badge, and due time.

struct TaskDetailCard: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(task.isCompleted ? Color.success : Color.textTertiary)
                    .animation(.snappy, value: task.isCompleted)
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body(15, weight: .medium))
                    .foregroundStyle(task.isCompleted ? Color.textTertiary : Color.textPrimary)
                    .strikethrough(task.isCompleted, color: Color.textTertiary)
                    .lineLimit(2)

                HStack(spacing: Spacing.sm) {
                    // Priority badge
                    priorityBadge

                    // Due time
                    if let dueDate = task.dueDate {
                        Label(timeString(dueDate), systemImage: "clock")
                            .font(.body(11))
                            .foregroundStyle(isOverdue(dueDate) ? Color.danger : Color.textTertiary)
                    }
                }
            }

            Spacer()

            // Note indicator
            if !task.note.isEmpty {
                Image(systemName: "note.text")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(Spacing.md)
        .background(Color.bgElevated)
        .cornerRadius(Radius.md)
    }

    private var priorityBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: task.priority.icon)
                .font(.system(size: 9, weight: .bold))
            Text(task.priority.label)
                .font(.body(11, weight: .medium))
        }
        .foregroundStyle(priorityColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(priorityColor.opacity(0.12))
        .cornerRadius(Radius.sm)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low:    return Color.textTertiary
        case .medium: return Color.accent
        case .high:   return Color.danger
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
