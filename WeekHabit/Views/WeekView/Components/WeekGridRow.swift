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

                        Text(habit.trackingKind == .quantity ? habit.targetPerSessionText : habit.scheduleSummaryText)
                            .font(AppFont.formSectionText2)
                            .foregroundStyle(AppColor.subtleText)
                            .lineLimit(1)

                        WeekProgressBar(
                            progress: habit.weekProgress(reference: referenceDate),
                            categoryColor: AppColor.accent
                        )
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                HStack(spacing: WeekGridLayout.cellSpacing) {
                    ForEach(daysInWeek, id: \.self) { date in
                        WeekGridCell(
                            state: cellState(for: date),
                            categoryColor: AppColor.accent,
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
        .shadow(color: AppColor.strongText.opacity(0.10), radius: 12, x: 0, y: 6)
    }

    private func cellState(for date: Date) -> WeekGridCell.State {
        let startOfDay = AppCalendar.startOfDay(for: date)
        let todayStart = AppCalendar.startOfDay(for: today)

        if startOfDay > todayStart {
            return .future
        }

        if !habit.isLoggable(on: date) {
            return .inactive
        }

        if habit.trackingKind == .quantity && habit.totalValue(on: date) > 0 && !habit.isCompleted(on: date) {
            return .partial
        }

        return habit.isCompleted(on: date) ? .completed : .pending
    }
}
