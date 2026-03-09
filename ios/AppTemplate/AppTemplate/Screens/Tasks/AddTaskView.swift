import SwiftUI

// MARK: - TaskFormView
// Bottom sheet matching the Stitch create-task reference.

struct TaskFormView: View {
    @ObservedObject var vm: TasksViewModel
    @Binding var isPresented: Bool
    let task: TaskItem?

    @State private var title: String
    @State private var note: String
    @State private var priority: TaskItem.Priority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var selectedCategoryId: String?
    @State private var repeatFrequency: TaskItem.RepeatFrequency?
    @State private var showCustomCategoryComposer = false
    @State private var customCategoryName = ""
    @State private var customCategoryEmoji = ""
    @State private var isCreatingCategory = false

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
        self._selectedCategoryId = State(initialValue: task?.categoryId)
        self._repeatFrequency = State(initialValue: task?.repeatFrequency)
    }

    @FocusState private var titleFocused: Bool

    private var isEditing: Bool { task != nil }
    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }
    private var headerTitle: String { isEditing ? "Edit Task" : "New Task" }
    private var submitTitle: String { isEditing ? "Save Changes" : "Add Task" }
    private var submitIcon: String { isEditing ? "checkmark" : "plus" }
    private var selectedCategory: TaskCategory? {
        vm.category(with: selectedCategoryId) ?? fallbackTaskCategory
    }

    private var fallbackTaskCategory: TaskCategory? {
        guard let task,
              let categoryId = task.categoryId,
              let categoryName = task.categoryName else {
            return nil
        }

        return TaskCategory(
            id: categoryId,
            userId: nil,
            name: categoryName,
            emoji: task.categoryEmoji ?? "",
            slug: nil,
            isDefault: false,
            createdAt: nil,
            updatedAt: nil
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.border)
                .frame(width: 48, height: 5)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.lg)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    topModePicker

                    TextField("Task title", text: $title)
                        .font(.display(30, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .textFieldStyle(.plain)
                        .focused($titleFocused)
                        .accessibilityIdentifier("taskForm.titleField")

                    TextField("Task description", text: $note, axis: .vertical)
                        .font(.body(18))
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2...4)
                        .textFieldStyle(.plain)
                        .accessibilityIdentifier("taskForm.noteField")

                    Rectangle()
                        .fill(Color.border)
                        .frame(height: 1)
                        .overlay(
                            HStack(spacing: 4) {
                                ForEach(0..<24, id: \.self) { index in
                                    Circle()
                                        .fill(index.isMultiple(of: 2) ? Color.clear : Color.bgElevated)
                                        .frame(width: 2, height: 2)
                                }
                            }
                        )

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Sub tasks")
                            .font(.body(12, weight: .bold))
                            .tracking(1.1)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.textSecondary)

                        Button {
                            HapticManager.selection()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.textSecondary)
                                .frame(width: 42, height: 42)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.md)
                                        .stroke(Color.border, style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        sectionTitle("Category")

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm) {
                                categoryChip(nil)

                                ForEach(vm.categories) { category in
                                    categoryChip(category)
                                }

                                Button {
                                    withAnimation(.snappy) {
                                        showCustomCategoryComposer.toggle()
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 12, weight: .bold))
                                        Text("Custom")
                                            .font(.body(13, weight: .bold))
                                    }
                                    .padding(.horizontal, Spacing.md)
                                    .frame(height: 40)
                                    .foregroundStyle(Color.textPrimary)
                                    .background(Color.bgSurface)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.border.opacity(0.8), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                    )
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("taskForm.customCategoryButton")
                            }
                            .padding(.vertical, 2)
                        }

                        if showCustomCategoryComposer {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack(spacing: Spacing.sm) {
                                    TextField("😀", text: $customCategoryEmoji)
                                        .font(.display(26, weight: .semibold))
                                        .multilineTextAlignment(.center)
                                        .frame(width: 64, height: 54)
                                        .background(Color.bgSurface)
                                        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                                        .accessibilityIdentifier("taskForm.customCategoryEmojiField")

                                    TextField("Category name", text: $customCategoryName)
                                        .font(.body(15, weight: .medium))
                                        .padding(.horizontal, Spacing.md)
                                        .frame(height: 54)
                                        .background(Color.bgSurface)
                                        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                                        .accessibilityIdentifier("taskForm.customCategoryNameField")
                                }

                                Button(action: createCustomCategory) {
                                    HStack(spacing: 8) {
                                        if isCreatingCategory {
                                            ProgressView()
                                                .controlSize(.small)
                                        }
                                        Text(isCreatingCategory ? "Creating..." : "Create category")
                                            .font(.body(13, weight: .bold))
                                    }
                                    .foregroundStyle(Color.textPrimary)
                                    .padding(.horizontal, Spacing.md)
                                    .frame(height: 42)
                                    .background(Color.bgSurface)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .disabled(isCreatingCategory || customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || customCategoryEmoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .accessibilityIdentifier("taskForm.createCategorySubmitButton")
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        sectionTitle("Repeat")

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm) {
                                repeatChip(nil)

                                ForEach(TaskItem.RepeatFrequency.allCases) { frequency in
                                    repeatChip(frequency)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(spacing: Spacing.sm) {
                            scheduleChip(
                                label: hasDueDate ? dayChipLabel : "No date",
                                systemName: hasDueDate ? nil : "calendar.badge.minus",
                                accent: hasDueDate
                            ) {
                                withAnimation(.snappy) {
                                    hasDueDate.toggle()
                                    if hasDueDate {
                                        dueDate = vm.selectedDate
                                    } else {
                                        repeatFrequency = nil
                                    }
                                }
                            }

                            scheduleChip(
                                label: hasDueDate ? timeChipLabel : "All day",
                                systemName: "clock",
                                accent: hasDueDate
                            ) {
                                hasDueDate = true
                            }

                            Spacer()

                            Button {
                                withAnimation(.snappy) {
                                    hasDueDate.toggle()
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Color.textPrimary)
                                    .frame(width: 48, height: 48)
                                    .background(Color.bgSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                            }
                            .buttonStyle(.plain)
                        }

                        if hasDueDate {
                            DatePicker(
                                "Due",
                                selection: $dueDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .tint(Color.accent)
                            .accessibilityIdentifier("taskForm.dueDatePicker")
                        }

                        HStack(spacing: Spacing.sm) {
                            ForEach(TaskItem.Priority.allCases, id: \.self) { value in
                                priorityChip(value)
                            }
                        }
                    }

                    Button(action: submit) {
                        Text(submitTitle)
                            .font(.body(20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 62)
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    .buttonStyle(.plain)
                    .opacity(isValid ? 1 : 0.45)
                    .disabled(!isValid)
                    .accessibilityIdentifier("taskForm.submitButton")
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxxl)
            }
        }
        .background(Color.bgElevated)
        .onAppear {
            titleFocused = true
        }
    }

    private var topModePicker: some View {
        HStack(spacing: Spacing.sm) {
            modeChip(title: "Task", systemName: "checkmark.circle", active: true)
            modeChip(title: "Event", systemName: "calendar", active: false)
            modeChip(title: "Habit", systemName: "repeat", active: false)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.body(12, weight: .bold))
            .tracking(1.1)
            .textCase(.uppercase)
            .foregroundStyle(Color.textSecondary)
    }

    private func modeChip(title: String, systemName: String, active: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
            Text(title)
                .font(.body(13, weight: active ? .bold : .medium))
        }
        .foregroundStyle(active ? Color.textPrimary : Color.textSecondary)
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .background(active ? Color.bg : Color.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private func scheduleChip(label: String, systemName: String?, accent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemName {
                    Image(systemName: systemName)
                        .font(.system(size: 12, weight: .bold))
                } else {
                    Circle()
                        .fill(Color.danger)
                        .frame(width: 8, height: 8)
                }

                Text(label)
                    .font(.body(13, weight: .bold))
            }
            .foregroundStyle(accent ? Color.textPrimary : Color.textSecondary)
            .padding(.horizontal, Spacing.md)
            .frame(height: 42)
            .background(Color.bgSurface)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var dayChipLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: dueDate)
    }

    private var timeChipLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: dueDate)
    }

    private func priorityChip(_ p: TaskItem.Priority) -> some View {
        let isSelected = priority == p
        return Button {
            priority = p
            HapticManager.selection()
        } label: {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(chipColor(p))
                    .frame(width: 10, height: 10)
                Text(p.label)
                    .font(.body(13, weight: .bold))
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 40)
            .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)
            .background(isSelected ? Color.bgSurface : Color.bgSurface.opacity(0.7))
            .overlay(
                Capsule()
                    .stroke(isSelected ? chipColor(p).opacity(0.65) : Color.clear, lineWidth: 1.5)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func categoryChip(_ category: TaskCategory?) -> some View {
        let isSelected = selectedCategoryId == category?.id || (category == nil && selectedCategoryId == nil)

        return Button {
            selectedCategoryId = category?.id
            HapticManager.selection()
        } label: {
            HStack(spacing: 6) {
                if let category {
                    Text(category.emoji)
                    Text(category.name)
                        .font(.body(13, weight: .bold))
                } else {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 12, weight: .bold))
                    Text("None")
                        .font(.body(13, weight: .bold))
                }
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 40)
            .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)
            .background(isSelected ? Color.bgSurface : Color.bgSurface.opacity(0.78))
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.accent.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func repeatChip(_ frequency: TaskItem.RepeatFrequency?) -> some View {
        let isSelected = repeatFrequency == frequency

        return Button {
            repeatFrequency = frequency
            if frequency != nil {
                hasDueDate = true
            }
            HapticManager.selection()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: frequency?.icon ?? "slash.circle")
                    .font(.system(size: 12, weight: .bold))

                Text(frequency?.label ?? "None")
                    .font(.body(13, weight: .bold))
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 40)
            .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)
            .background(isSelected ? Color.bgSurface : Color.bgSurface.opacity(0.78))
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.textPrimary.opacity(0.15) : Color.clear, lineWidth: 1.5)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("taskForm.repeat.\(frequency?.rawValue ?? "none")")
    }

    private func chipColor(_ p: TaskItem.Priority) -> Color {
        switch p {
        case .low:    return Color.success
        case .medium: return Color.warning
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
                dueDate: sanitizedDueDate,
                category: selectedCategory,
                repeatFrequency: sanitizedDueDate == nil ? nil : repeatFrequency
            )
        } else {
            vm.addTask(
                title: sanitizedTitle,
                note: sanitizedNote,
                priority: priority,
                dueDate: sanitizedDueDate,
                category: selectedCategory,
                repeatFrequency: sanitizedDueDate == nil ? nil : repeatFrequency
            )
        }

        isPresented = false
    }

    private func createCustomCategory() {
        guard !isCreatingCategory else { return }

        let name = customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let emoji = customCategoryEmoji.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty, !emoji.isEmpty else { return }

        isCreatingCategory = true

        Task {
            let createdCategory = await vm.createCategory(name: name, emoji: emoji)

            await MainActor.run {
                isCreatingCategory = false

                guard let createdCategory else { return }

                selectedCategoryId = createdCategory.id
                customCategoryName = ""
                customCategoryEmoji = ""
                showCustomCategoryComposer = false
                HapticManager.success()
            }
        }
    }
}
