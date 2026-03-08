import SwiftUI

// MARK: - TaskDetailCard
// Single task row matching the Stitch today-list visual direction.

struct TaskDetailCard: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Button(action: onToggle) {
                checkbox
            }
            .buttonStyle(.plain)
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    Text(task.title)
                        .font(.body(16, weight: .bold))
                        .foregroundStyle(task.isCompleted ? Color.textSecondary : Color.textPrimary)
                        .strikethrough(task.isCompleted, color: Color.textTertiary)
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    priorityIndicator
                }

                if !task.note.isEmpty {
                    Text(task.note)
                        .font(.body(13))
                        .foregroundStyle(task.isCompleted ? Color.textTertiary : Color.textSecondary)
                        .lineLimit(2)
                }

                if let dueDate = task.dueDate {
                    Label(timeString(dueDate), systemImage: "clock")
                        .font(.body(11, weight: .medium))
                        .foregroundStyle(isOverdue(dueDate) ? Color.danger : Color.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.lg)
    }

    private var checkbox: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(task.isCompleted ? Color.success : Color.clear)
            .stroke(task.isCompleted ? Color.success : Color.textTertiary, lineWidth: task.isCompleted ? 0 : 1.75)
            .frame(width: 20, height: 20)
            .overlay {
                if task.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white)
                }
            }
            .animation(.snappy, value: task.isCompleted)
    }

    private var priorityIndicator: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(priorityColor)
            .frame(width: 11, height: 11)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low:
            return Color.success
        case .medium:
            return Color.warning
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
