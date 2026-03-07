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
                    .foregroundStyle(isSelected ? Color.white : Color.textSecondary)

                VStack(spacing: 4) {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.body(14, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(isSelected ? Color.white : Color.textPrimary)

                    Circle()
                        .fill(isSelected ? Color.white : Color.textPrimary)
                        .frame(width: 4, height: 4)
                        .opacity(hasTasks(on: date) ? 1 : 0)
                }
            }
            .frame(width: 44, height: 68)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.black : Color.clear)
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
}

#Preview {
    WeekCalendarStrip(selectedDate: .constant(Date()), tasks: [])
        .background(Color.bg)
}
