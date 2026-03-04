import SwiftUI

// MARK: - AddTaskView
// Bottom sheet form for creating a new task. Shown via the center FAB.

struct AddTaskView: View {
    @ObservedObject var vm: TasksViewModel
    @Binding var isPresented: Bool

    @State private var title = ""
    @State private var note = ""
    @State private var priority: TaskItem.Priority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    @FocusState private var titleFocused: Bool

    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Header
            HStack {
                Text("New Task")
                    .font(.display(22))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.textTertiary)
                }
                .buttonStyle(.plain)
            }

            // Title
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Title")
                    .font(.body(13, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)

                TextField("What do you need to do?", text: $title)
                    .font(.body(16))
                    .padding(Spacing.md)
                    .background(Color.bgSurface)
                    .cornerRadius(Radius.md)
                    .focused($titleFocused)
            }

            // Note
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Note (optional)")
                    .font(.body(13, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)

                TextField("Add details...", text: $note, axis: .vertical)
                    .font(.body(15))
                    .lineLimit(3...5)
                    .padding(Spacing.md)
                    .background(Color.bgSurface)
                    .cornerRadius(Radius.md)
            }

            // Priority
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Priority")
                    .font(.body(13, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)

                HStack(spacing: Spacing.sm) {
                    ForEach(TaskItem.Priority.allCases, id: \.self) { p in
                        priorityChip(p)
                    }
                }
            }

            // Due date
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Toggle(isOn: $hasDueDate.animation()) {
                    Text("Due date")
                        .font(.body(13, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                }
                .tint(Color.accent)

                if hasDueDate {
                    DatePicker(
                        "Due",
                        selection: $dueDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }

            Spacer()

            // Submit
            AppButton("Add Task", style: .primary, icon: "plus") {
                guard isValid else { return }
                vm.addTask(
                    title: title.trimmingCharacters(in: .whitespaces),
                    note: note.trimmingCharacters(in: .whitespaces),
                    priority: priority,
                    dueDate: hasDueDate ? dueDate : nil
                )
                isPresented = false
            }
            .opacity(isValid ? 1 : 0.5)
        }
        .padding(Spacing.xl)
        .onAppear {
            titleFocused = true
        }
    }

    private func priorityChip(_ p: TaskItem.Priority) -> some View {
        let isSelected = priority == p
        return Button {
            priority = p
            HapticManager.selection()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: p.icon)
                    .font(.system(size: 12, weight: .bold))
                Text(p.label)
                    .font(.body(13, weight: .semibold))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .foregroundStyle(isSelected ? .white : chipColor(p))
            .background(isSelected ? chipColor(p) : chipColor(p).opacity(0.12))
            .cornerRadius(Radius.full)
        }
        .buttonStyle(.plain)
    }

    private func chipColor(_ p: TaskItem.Priority) -> Color {
        switch p {
        case .low:    return Color.textTertiary
        case .medium: return Color.accent
        case .high:   return Color.danger
        }
    }
}
