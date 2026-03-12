import SwiftUI

// MARK: - TaskDetailView

struct TaskDetailView: View {
    @ObservedObject var vm: TasksViewModel
    let task: TaskItem

    @Environment(\.dismiss) private var dismiss
    @State private var showEditTask = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Title + status
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        TaskCompletionCheckbox(isChecked: task.isCompleted, size: 18, cornerRadius: 5)
                            .padding(.top, 4)

                        Text(task.title)
                            .font(.display(22, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                            .strikethrough(task.isCompleted, color: Color.textTertiary)
                    }
                    .padding(.bottom, Spacing.lg)

                    // Property rows
                    propertyDivider

                    propertyRow("Status", value: task.isCompleted ? "Done" : "In progress")
                    propertyDivider

                    propertyRow("Priority", value: task.priority.label, valueColor: priorityColor)
                    propertyDivider

                    if let category = task.categoryDisplayText {
                        propertyRow("Category", value: category)
                        propertyDivider
                    }

                    if let repeatText = task.repeatDisplayText {
                        propertyRow("Repeats", value: repeatText)
                        propertyDivider
                    }

                    if let dueDate = task.dueDate {
                        propertyRow("Due date", value: shortDateText(dueDate), valueColor: isOverdue(dueDate) ? Color.danger : nil)
                        propertyDivider
                    }

                    propertyRow("Created", value: shortDateText(task.createdAt))
                    propertyDivider

                    if let completedAt = task.completedAt {
                        propertyRow("Completed", value: shortDateText(completedAt))
                        propertyDivider
                    }

                    // Notes section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("NOTES")
                            .font(.body(11, weight: .semibold))
                            .foregroundStyle(Color.textTertiary)
                            .tracking(0.8)

                        Text(task.note.isEmpty ? "No notes added." : task.note)
                            .font(.body(15))
                            .foregroundStyle(task.note.isEmpty ? Color.textTertiary : Color.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, Spacing.xl)
                    .padding(.bottom, Spacing.xl)

                    // Actions
                    VStack(spacing: Spacing.md) {
                        Button {
                            vm.toggleComplete(task)
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                                    .font(.body(13, weight: .medium))
                                Text(task.isCompleted ? "Mark as Pending" : "Mark as Completed")
                                    .font(.body(14, weight: .medium))
                            }
                            .foregroundStyle(Color.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md)
                                    .stroke(Color.border, lineWidth: 1)
                            )
                        }
                        .accessibilityIdentifier("taskDetail.toggleStatusButton")

                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Text("Delete task")
                                .font(.body(13, weight: .medium))
                                .foregroundStyle(Color.danger)
                        }
                        .accessibilityIdentifier("taskDetail.deleteButton")
                    }
                }
                .padding(Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showEditTask = true
                }
                .accessibilityIdentifier("taskDetail.editButton")
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

    // MARK: - Components

    private var propertyDivider: some View {
        Rectangle()
            .fill(Color.border.opacity(0.4))
            .frame(height: 0.5)
    }

    private func propertyRow(_ label: String, value: String, valueColor: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(.body(13, weight: .regular))
                .foregroundStyle(Color.textTertiary)
                .frame(width: 90, alignment: .leading)

            Text(value)
                .font(.body(14, weight: .medium))
                .foregroundStyle(valueColor ?? Color.textPrimary)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low:    return Color.success
        case .medium: return Color.warning
        case .high:   return Color.danger
        }
    }

    private func shortDateText(_ date: Date) -> String {
        date.formatted(.dateTime.month().day().year().hour().minute())
    }

    private func isOverdue(_ date: Date) -> Bool {
        !task.isCompleted && date < Date()
    }
}
