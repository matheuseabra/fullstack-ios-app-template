import SwiftUI

// MARK: - WeekCalendarStrip
// Horizontal week selector matching the Stitch timeline reference.

struct WeekCalendarStrip: View {
    @Binding var selectedDate: Date
    let tasks: [TaskItem]

    private let calendar = Calendar.current

    private var days: [Date] {
        let anchor = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: anchor)
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(days, id: \.self) { date in
                        dayCard(date)
                            .id(date)
                    }
                }
                .padding(.horizontal, 2)
            }
            .simultaneousGesture(daySwipeGesture)
            .onAppear {
                proxy.scrollTo(selectedDate, anchor: .center)
            }
            .onChange(of: selectedDate) { _, newValue in
                withAnimation(.snappy(duration: 0.2)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    private var daySwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height),
                      abs(value.translation.width) > 44 else {
                    return
                }

                shiftDay(by: value.translation.width < 0 ? 1 : -1)
            }
    }

    private func dayCard(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)

        return Button {
            withAnimation(.snappy(duration: 0.2)) {
                selectedDate = date
            }
            HapticManager.selection()
        } label: {
            VStack(spacing: 6) {
                Text(dayOfWeek(date))
                    .font(.body(10, weight: .bold))
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textSecondary)

                VStack(spacing: 4) {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.body(14, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(Color.textPrimary)

                    Circle()
                        .fill(Color.textPrimary)
                        .frame(width: 4, height: 4)
                        .opacity(hasTasks(on: date) ? 1 : 0)
                }
            }
            .frame(width: 44, height: 68)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.textPrimary : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private func hasTasks(on date: Date) -> Bool {
        let dayStart = calendar.startOfDay(for: date)

        return tasks.contains { task in
            if let dueDate = task.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: dayStart)
            }

            return calendar.isDateInToday(dayStart)
        }
    }

    private func shiftDay(by value: Int) {
        guard let nextDate = calendar.date(byAdding: .day, value: value, to: selectedDate) else {
            return
        }

        withAnimation(.snappy(duration: 0.22)) {
            selectedDate = nextDate
        }
        HapticManager.selection()
    }
}

#Preview {
    WeekCalendarStrip(selectedDate: .constant(Date()), tasks: [])
        .background(Color.bg)
}
