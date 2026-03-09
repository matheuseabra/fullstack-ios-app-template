import SwiftUI

// MARK: - TaskDetailCard
// Minimal, Notion-style task row.

struct TaskDetailCard: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onToggle) {
                TaskCompletionCheckbox(isChecked: task.isCompleted, size: 20, cornerRadius: 6)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.body(15, weight: .medium))
                    .foregroundStyle(task.isCompleted ? Color.textTertiary : Color.textPrimary)
                    .strikethrough(task.isCompleted, color: Color.textTertiary)
                    .lineLimit(1)

                if !task.note.isEmpty {
                    Text(task.note)
                        .lineLimit(1)
                        .font(.body(12))
                        .foregroundStyle(Color.textSecondary)
                }

                metadataRow
                    .foregroundStyle(
                        task.dueDate.map({ isOverdue($0) }) == true
                            ? Color.danger
                            : Color.textTertiary
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .opacity(task.isCompleted ? 0.65 : 1)
        .animation(.easeOut(duration: 0.15), value: task.isCompleted)
    }

    private var metadataRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                metadataBadges
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if let category = task.categoryDisplayText {
                        metadataBadge(text: category)
                    }

                    priorityBadge
                }

                HStack(spacing: 6) {
                    if let dueDate = task.dueDate {
                        metadataBadge(text: timeString(dueDate), icon: "clock")
                    }

                    if let repeatLabel = task.repeatFrequency?.label {
                        metadataBadge(text: repeatLabel, icon: "repeat")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var metadataBadges: some View {
        if let category = task.categoryDisplayText {
            metadataBadge(text: category)
        }

        priorityBadge

        if let dueDate = task.dueDate {
            metadataBadge(text: timeString(dueDate), icon: "clock")
        }

        if let repeatLabel = task.repeatFrequency?.label {
            metadataBadge(text: repeatLabel, icon: "repeat")
        }
    }

    private var priorityBadge: some View {
        metadataBadge(text: task.priority.label, dotColor: priorityColor)
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

    private func metadataBadge(text: String, icon: String? = nil, dotColor: Color? = nil) -> some View {
        HStack(spacing: 5) {
            if let dotColor {
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
            }

            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }

            Text(text)
                .font(.body(11, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(Color.textTertiary)
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(Color.bgSurface)
        .clipShape(Capsule())
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
