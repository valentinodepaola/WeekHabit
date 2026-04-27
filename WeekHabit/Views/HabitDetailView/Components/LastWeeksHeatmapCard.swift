//
//  LastWeeksHeatmapCard.swift
//  WeekHabit
//

import SwiftUI

struct LastWeeksHeatmapCard: View {
    let habit: Habit
    var weeks: Int = 10
    var referenceDate: Date = .now

    private var category: HabitCategory {
        habit.displayCategory
    }

    private var matrix: [[CellState]] {
        habit.completionMatrix(weeks: weeks, reference: referenceDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ÚLTIMAS 10 SEMANAS")
                .font(AppFont.formSectionText)
                .foregroundStyle(AppColor.mutedText)
                .textCase(.uppercase)

            HStack(alignment: .top, spacing: 4) {
                ForEach(Array(matrix.enumerated()), id: \.offset) { weekIndex, week in
                    VStack(spacing: 4) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, state in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(color(for: state, intensity: intensity(for: weekIndex)))
                                .frame(width: 12, height: 12)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }

    private func intensity(for weekIndex: Int) -> Double {
        guard habit.targetDaysPerWeek > 0,
              matrix.indices.contains(weekIndex) else {
            return 0
        }

        let completedDays = matrix[weekIndex].filter { $0 == .completed }.count
        let ratio = min(1, Double(completedDays) / Double(habit.targetDaysPerWeek))

        switch ratio {
        case 0:
            return 0
        case 0...0.25:
            return 0.25
        case 0.25...0.5:
            return 0.5
        case 0.5...0.75:
            return 0.75
        default:
            return 1
        }
    }

    private func color(for state: CellState, intensity: Double) -> Color {
        switch state {
        case .completed:
            return category.color.opacity(max(0.25, intensity))
        case .missed:
            return category.color.opacity(0.10)
        case .inactive, .future:
            return AppColor.bgLight
        }
    }
}

#Preview {
    LastWeeksHeatmapCard(
        habit: Habit(
            title: "Meditar",
            category: .personal,
            targetDaysPerWeek: 5,
            activeDaysOfWeek: Set(Weekday.ordered)
        )
    )
    .padding()
    .background(AppColor.bgLight)
}
