import SwiftUI

// MARK: - WeekCalendarStrip
// Horizontal scrollable week view with day pills. Matches the mood tracker reference layout.

struct WeekCalendarStrip: View {
    @Binding var selectedDate: Date

    private let calendar = Calendar.current
    private let today = Date()

    // Show 2 weeks (7 days back + today + 6 days forward)
    private var days: [Date] {
        (-7...6).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(days, id: \.self) { date in
                        dayPill(date)
                            .id(date)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            .onAppear {
                proxy.scrollTo(today, anchor: .center)
            }
        }
    }

    private func dayPill(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)

        return Button {
            withAnimation(.snappy(duration: 0.2)) {
                selectedDate = date
            }
            HapticManager.selection()
        } label: {
            VStack(spacing: 6) {
                Text(dayOfWeek(date))
                    .font(.body(11, weight: .medium))
                    .foregroundStyle(isSelected ? .white : Color.textTertiary)

                Text("\(calendar.component(.day, from: date))")
                    .font(.body(16, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? .white : Color.textPrimary)
            }
            .frame(width: 44, height: 64)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(isSelected ? Color.accent : Color.bgSurface)
            )
            .overlay(
                isToday && !isSelected
                    ? Circle()
                        .fill(Color.accent)
                        .frame(width: 5, height: 5)
                        .offset(y: 26)
                    : nil
            )
        }
        .buttonStyle(.plain)
    }

    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
}

#Preview {
    WeekCalendarStrip(selectedDate: .constant(Date()))
        .background(Color.bg)
}
