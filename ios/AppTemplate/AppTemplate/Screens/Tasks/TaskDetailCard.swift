import SwiftUI

// MARK: - TaskDetailCard
// Minimal, Notion-style task row.

struct TaskDetailCard: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onToggle) {
                checkbox
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body(15, weight: .medium))
                    .foregroundStyle(task.isCompleted ? Color.textTertiary : Color.textPrimary)
                    .strikethrough(task.isCompleted, color: Color.textTertiary)
                    .lineLimit(1)

                if !task.note.isEmpty || task.dueDate != nil {
                    HStack(spacing: 8) {
                        if !task.note.isEmpty {
                            Text(task.note)
                                .lineLimit(1)
                        }

                        if !task.note.isEmpty && task.dueDate != nil {
                            Text("·")
                        }

                        if let dueDate = task.dueDate {
                            Text(timeString(dueDate))
                        }
                    }
                    .font(.body(12))
                    .foregroundStyle(
                        task.dueDate.map({ isOverdue($0) }) == true
                            ? Color.danger
                            : Color.textTertiary
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if task.priority == .high {
                Circle()
                    .fill(Color.danger.opacity(0.8))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, 12)
        .opacity(task.isCompleted ? 0.65 : 1)
        .animation(.easeOut(duration: 0.15), value: task.isCompleted)
    }

    private var checkbox: some View {
        Circle()
            .stroke(task.isCompleted ? Color.textTertiary : Color.textTertiary.opacity(0.6), lineWidth: 1.5)
            .frame(width: 20, height: 20)
            .overlay {
                if task.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }
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
