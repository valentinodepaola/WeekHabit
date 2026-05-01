//
//  WeekGridRow.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 01/05/26.
//

import SwiftUI

struct WeekGridRow: View {
    
    let habit: Habit
    let daysInWeek: [Date]
    let referenceDate: Date
    let today: Date
    let onSelectHabit: () -> Void
    let onToggle: (Date) -> Void

    var body: some View {
        HStack(spacing: 0) {
            habit.displayCategory.color
                .frame(width: WeekGridLayout.categoryStripWidth)

            VStack(alignment: .leading, spacing: 14) {
                Button(action: onSelectHabit) {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(habit.title)
                                .font(AppFont.body2)
                                .foregroundStyle(AppColor.strongText)
                                .lineLimit(1)

                            Spacer(minLength: 8)

                            Text("\(habit.completedDaysThisWeek(reference: referenceDate))/\(habit.targetDaysPerWeek)")
                                .font(AppFont.formSectionText2)
                                .foregroundStyle(AppColor.mutedText)
                        }

                        WeekProgressBar(
                            progress: habit.weekProgress(reference: referenceDate),
                            categoryColor: habit.displayCategory.color
                        )
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                HStack(spacing: WeekGridLayout.cellSpacing) {
                    ForEach(daysInWeek, id: \.self) { date in
                        WeekGridCell(
                            state: cellState(for: date),
                            categoryColor: habit.displayCategory.color,
                            onTap: { onToggle(date) }
                        )
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }

    private func cellState(for date: Date) -> WeekGridCell.State {
        let startOfDay = AppCalendar.startOfDay(for: date)
        let todayStart = AppCalendar.startOfDay(for: today)

        if startOfDay > todayStart {
            return .future
        }

        if !habit.isActive(on: date) {
            return .inactive
        }

        return habit.isCompleted(on: date) ? .completed : .pending
    }
}
