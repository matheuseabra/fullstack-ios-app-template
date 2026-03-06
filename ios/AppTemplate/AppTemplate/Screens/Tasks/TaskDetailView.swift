import SwiftUI

// MARK: - TaskDetailView
// Full-screen detail view for a task with edit and delete actions.

struct TaskDetailView: View {
    @ObservedObject var vm: TasksViewModel
    let task: TaskItem

    @Environment(\.dismiss) private var dismiss
    @State private var showEditTask = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(task.title)
                            .font(.display(28, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                            .strikethrough(task.isCompleted, color: Color.textTertiary)

                        Text(task.isCompleted ? "Completed" : "In progress")
                            .font(.body(13, weight: .semibold))
                            .foregroundStyle(task.isCompleted ? Color.success : Color.accent)
                    }

                    HStack(spacing: Spacing.sm) {
                        priorityBadge

                        if let dueDate = task.dueDate {
                            Label(dueDateText(dueDate), systemImage: "calendar")
                                .font(.body(12, weight: .semibold))
                                .foregroundStyle(isOverdue(dueDate) ? Color.danger : Color.textSecondary)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(Color.bgSurface)
                                .cornerRadius(Radius.full)
                        } else {
                            Label("No due date", systemImage: "calendar.badge.minus")
                                .font(.body(12, weight: .semibold))
                                .foregroundStyle(Color.textTertiary)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(Color.bgSurface)
                                .cornerRadius(Radius.full)
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Notes")
                            .font(.body(13, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)

                        Text(task.note.isEmpty ? "No notes added." : task.note)
                            .font(.body(15))
                            .foregroundStyle(task.note.isEmpty ? Color.textTertiary : Color.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Spacing.md)
                            .background(Color.bgElevated)
                            .cornerRadius(Radius.md)
                    }

                    AppButton(task.isCompleted ? "Mark as Pending" : "Mark as Completed", style: .ghost) {
                        vm.toggleComplete(task)
                    }
                    .accessibilityIdentifier("taskDetail.toggleStatusButton")

                    metadataCard
                }
                .padding(Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }
        }
        .navigationTitle("Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Edit") {
                    showEditTask = true
                }
                .accessibilityIdentifier("taskDetail.editButton")

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityIdentifier("taskDetail.deleteButton")
            }
        }
        .alert("Delete Task?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                vm.deleteTask(task)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .drawer(isPresented: $showEditTask) {
            TaskFormView(vm: vm, isPresented: $showEditTask, task: task)
        }
    }

    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Details")
                .font(.body(13, weight: .semibold))
                .foregroundStyle(Color.textSecondary)

            metadataRow("Created", value: fullDateText(task.createdAt))
            metadataRow("Updated", value: fullDateText(task.updatedAt))
            metadataRow("Completion", value: task.completedAt.map(fullDateText) ?? "Not completed")
        }
        .padding(Spacing.md)
        .background(Color.bgElevated)
        .cornerRadius(Radius.md)
    }

    private func metadataRow(_ label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Text(label)
                .font(.body(12, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
                .frame(width: 92, alignment: .leading)

            Text(value)
                .font(.body(13))
                .foregroundStyle(Color.textPrimary)

            Spacer(minLength: 0)
        }
    }

    private var priorityBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: task.priority.icon)
                .font(.system(size: 10, weight: .bold))
            Text(task.priority.label)
                .font(.body(12, weight: .semibold))
        }
        .foregroundStyle(priorityColor)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(priorityColor.opacity(0.12))
        .cornerRadius(Radius.full)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low:    return Color.textTertiary
        case .medium: return Color.accent
        case .high:   return Color.danger
        }
    }

    private func dueDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func fullDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func isOverdue(_ date: Date) -> Bool {
        !task.isCompleted && date < Date()
    }
}
