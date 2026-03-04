import SwiftUI

// MARK: - TaskSummaryCard
// Circular progress ring + completion stats. Like the mood tracker's daily summary.

struct TaskSummaryCard: View {
    let completed: Int
    let total: Int
    let rate: Double

    var body: some View {
        HStack(spacing: Spacing.xl) {
            // Completion ring
            ZStack {
                Circle()
                    .stroke(Color.bgSurface, lineWidth: 8)
                    .frame(width: 72, height: 72)

                Circle()
                    .trim(from: 0, to: rate)
                    .stroke(
                        Color.accent,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.6), value: rate)

                Text("\(Int(rate * 100))%")
                    .font(.body(16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }

            // Stats
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Today's Progress")
                    .font(.body(14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Text("\(completed) of \(total) tasks completed")
                    .font(.body(13))
                    .foregroundStyle(Color.textSecondary)

                if total == 0 {
                    Text("No tasks scheduled for today")
                        .font(.body(12))
                        .foregroundStyle(Color.textTertiary)
                } else if completed == total {
                    Label("All done!", systemImage: "checkmark.circle.fill")
                        .font(.body(13, weight: .semibold))
                        .foregroundStyle(Color.success)
                }
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .background(Color.bgElevated)
        .cornerRadius(Radius.lg)
        .padding(.horizontal, Spacing.lg)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        TaskSummaryCard(completed: 3, total: 7, rate: 0.43)
        TaskSummaryCard(completed: 5, total: 5, rate: 1.0)
        TaskSummaryCard(completed: 0, total: 0, rate: 0)
    }
    .background(Color.bg)
}
