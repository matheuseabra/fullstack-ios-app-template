import SwiftUI

// MARK: - TaskFormView
// Bottom sheet form for creating and editing tasks.

struct TaskFormView: View {
    @ObservedObject var vm: TasksViewModel
    @Binding var isPresented: Bool
    let task: TaskItem?

    @State private var title: String
    @State private var note: String
    @State private var priority: TaskItem.Priority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date

    init(vm: TasksViewModel, isPresented: Binding<Bool>, task: TaskItem? = nil) {
        self._vm = ObservedObject(wrappedValue: vm)
        self._isPresented = isPresented
        self.task = task

        self._title = State(initialValue: task?.title ?? "")
        self._note = State(initialValue: task?.note ?? "")
        self._priority = State(initialValue: task?.priority ?? .medium)

        let initialDueDate = task?.dueDate ?? vm.selectedDate
        let createModeHasDueDate = task == nil
        self._hasDueDate = State(initialValue: task?.dueDate != nil || createModeHasDueDate)
        self._dueDate = State(initialValue: initialDueDate)
    }

    @FocusState private var titleFocused: Bool

    private var isEditing: Bool { task != nil }
    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }
    private var headerTitle: String { isEditing ? "Edit Task" : "New Task" }
    private var submitTitle: String { isEditing ? "Save Changes" : "Add Task" }
    private var submitIcon: String { isEditing ? "checkmark" : "plus" }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Header
            HStack {
                Text(headerTitle)
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
                .accessibilityIdentifier("taskForm.closeButton")
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
                    .accessibilityIdentifier("taskForm.titleField")
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
                    .accessibilityIdentifier("taskForm.noteField")
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
                .accessibilityIdentifier("taskForm.dueDateToggle")

                if hasDueDate {
                    DatePicker(
                        "Due",
                        selection: $dueDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .accessibilityIdentifier("taskForm.dueDatePicker")
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }

            Spacer()

            // Submit
            AppButton(submitTitle, style: .primary, icon: submitIcon, action: submit)
            .opacity(isValid ? 1 : 0.5)
            .accessibilityIdentifier("taskForm.submitButton")
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

    private func submit() {
        guard isValid else { return }

        let sanitizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedDueDate = hasDueDate ? dueDate : nil

        if let task {
            vm.updateTask(
                task,
                title: sanitizedTitle,
                note: sanitizedNote,
                priority: priority,
                dueDate: sanitizedDueDate
            )
        } else {
            vm.addTask(
                title: sanitizedTitle,
                note: sanitizedNote,
                priority: priority,
                dueDate: sanitizedDueDate
            )
        }

        isPresented = false
    }
}
