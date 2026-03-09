import SwiftUI

// MARK: - TaskFormView
// Minimal task sheet with compact rows and lightweight editors.

struct TaskFormView: View {
    private enum EditorSection: String {
        case category
        case schedule
        case recurrence = "repeat"
        case priority
        case detail
    }

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
    @State private var activeEditor: EditorSection?

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
    private var isValid: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var headerTitle: String { isEditing ? "Edit Task" : "New Task" }
    private var submitIcon: String { "checkmark" }
    private var selectedCategory: TaskCategory? {
        vm.category(with: selectedCategoryId) ?? fallbackTaskCategory
    }

    private var categorySummary: String {
        selectedCategory?.displayText ?? "Choose category"
    }

    private var scheduleSummary: String {
        guard hasDueDate else { return "No date" }

        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        if calendar.isDateInToday(dueDate) {
            return "Today at \(timeFormatter.string(from: dueDate))"
        }

        if calendar.isDateInTomorrow(dueDate) {
            return "Tomorrow at \(timeFormatter.string(from: dueDate))"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        return "\(dateFormatter.string(from: dueDate)) at \(timeFormatter.string(from: dueDate))"
    }

    private var repeatSummary: String {
        repeatFrequency?.label ?? "Does not repeat"
    }

    private var prioritySummary: String {
        priority.label
    }

    private var detailSummary: String {
        let trimmed = note
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")

        return trimmed.isEmpty ? "Add detail" : trimmed
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
                .padding(.bottom, Spacing.md)

            ZStack(alignment: .bottomTrailing) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        TextField(headerTitle, text: $title)
                            .font(.display(34, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .textFieldStyle(.plain)
                            .focused($titleFocused)
                            .accessibilityIdentifier("taskForm.titleField")

                        summaryRow(section: .category, systemName: "square.grid.2x2", value: categorySummary)
                        if activeEditor == .category {
                            editorCard(categoryEditor)
                        }

                        summaryRow(section: .schedule, systemName: "clock", value: scheduleSummary)
                        if activeEditor == .schedule {
                            editorCard(scheduleEditor)
                        }

                        summaryRow(section: .recurrence, systemName: "repeat", value: repeatSummary)
                        if activeEditor == .recurrence {
                            editorCard(repeatEditor)
                        }

                        summaryRow(section: .priority, systemName: "flag", value: prioritySummary, accent: chipColor(priority))
                        if activeEditor == .priority {
                            editorCard(priorityEditor)
                        }

                        summaryRow(section: .detail, systemName: "plus", value: detailSummary)
                        if activeEditor == .detail {
                            editorCard(detailEditor)
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, 132)
                }

                HStack(spacing: Spacing.lg) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("taskForm.closeButton")

                    Button(action: submit) {
                        Image(systemName: submitIcon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(isValid ? Color.accent.opacity(0.82) : Color.border)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(isValid ? 0.12 : 0), radius: 12, y: 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isValid)
                    .accessibilityIdentifier("taskForm.submitButton")
                }
                .padding(.trailing, Spacing.xl)
                .padding(.bottom, Spacing.xl)
            }
        }
        .background(Color.bgElevated)
        .onAppear {
            titleFocused = true
        }
    }

    private func summaryRow(section: EditorSection, systemName: String, value: String, accent: Color = Color.textPrimary) -> some View {
        Button {
            withAnimation(.snappy) {
                activeEditor = activeEditor == section ? nil : section
            }
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(accent)
                    .frame(width: 24)

                Text(value)
                    .font(.body(18, weight: .medium))
                    .foregroundStyle(valueColor(for: section))
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 3)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("taskForm.\(section.rawValue)Row")
    }

    private func valueColor(for section: EditorSection) -> Color {
        switch section {
        case .detail:
            return note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.textTertiary : Color.textPrimary
        case .category:
            return selectedCategory == nil ? Color.textSecondary : Color.textPrimary
        case .schedule:
            return hasDueDate ? Color.textPrimary : Color.textSecondary
        case .recurrence:
            return repeatFrequency == nil ? Color.textSecondary : Color.textPrimary
        case .priority:
            return Color.textPrimary
        }
    }

    private func editorCard<Content: View>(_ content: Content) -> some View {
        content
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
            .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var categoryEditor: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
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
                        .background(Color.bg)
                        .overlay(
                            Capsule()
                                .stroke(Color.border.opacity(0.8), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("taskForm.customCategoryButton")
                }
            }

            if showCustomCategoryComposer {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: Spacing.sm) {
                        TextField("😀", text: $customCategoryEmoji)
                            .font(.display(24, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .frame(width: 64, height: 52)
                            .background(Color.bg)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                            .accessibilityIdentifier("taskForm.customCategoryEmojiField")

                        TextField("Category name", text: $customCategoryName)
                            .font(.body(15, weight: .medium))
                            .padding(.horizontal, Spacing.md)
                            .frame(height: 52)
                            .background(Color.bg)
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
                        .background(Color.bg)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(
                        isCreatingCategory
                        || customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || customCategoryEmoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                    .accessibilityIdentifier("taskForm.createCategorySubmitButton")
                }
            }
        }
    }

    private var scheduleEditor: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Toggle(isOn: Binding(
                get: { hasDueDate },
                set: { newValue in
                    withAnimation(.snappy) {
                        hasDueDate = newValue
                        if newValue {
                            dueDate = task?.dueDate ?? vm.selectedDate
                        } else {
                            repeatFrequency = nil
                        }
                    }
                }
            )) {
                Text("Schedule this task")
                    .font(.body(14, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
            }
            .tint(Color.accent)

            if hasDueDate {
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Date")
                            .font(.body(11, weight: .bold))
                            .foregroundStyle(Color.textSecondary)
                        DatePicker(
                            "Date",
                            selection: $dueDate,
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Time")
                            .font(.body(11, weight: .bold))
                            .foregroundStyle(Color.textSecondary)
                        DatePicker(
                            "Time",
                            selection: $dueDate,
                            displayedComponents: [.hourAndMinute]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }
                }
                .accessibilityIdentifier("taskForm.dueDatePicker")
            }
        }
    }

    private var repeatEditor: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                repeatChip(nil)

                ForEach(TaskItem.RepeatFrequency.allCases) { frequency in
                    repeatChip(frequency)
                }
            }
        }
    }

    private var priorityEditor: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(TaskItem.Priority.allCases, id: \.self) { value in
                    priorityChip(value)
                }
            }
        }
    }

    private var detailEditor: some View {
        ZStack(alignment: .topLeading) {
            if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Add detail")
                    .font(.body(15))
                    .foregroundStyle(Color.textTertiary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.md)
            }

            TextEditor(text: $note)
                .font(.body(15))
                .foregroundStyle(Color.textPrimary)
                .frame(minHeight: 110)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .accessibilityIdentifier("taskForm.noteField")
        }
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
            .background(isSelected ? Color.bg : Color.bg.opacity(0.6))
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
            .background(isSelected ? Color.bg : Color.bg.opacity(0.65))
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
            .background(isSelected ? Color.bg : Color.bg.opacity(0.65))
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
