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

    private var habitColor: Color {
        habit.habitColor
    }

    private var completedCount: Int {
        habit.completedDaysThisWeek(reference: referenceDate)
    }

    private var progress: Double {
        habit.weekProgress(reference: referenceDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onSelectHabit) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(habitColor.opacity(0.16))
                            .frame(width: 42, height: 42)

                        Image(systemName: habit.iconName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(habitColor)
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(habit.title)
                                .font(AppFont.body2)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColor.strongText)
                                .lineLimit(1)

                            Spacer(minLength: 8)

                            WeekProgressPill(
                                completed: completedCount,
                                target: habit.targetDaysPerWeek,
                                color: habitColor
                            )
                        }

                        Text(subtitle)
                            .font(AppFont.formSectionText2)
                            .foregroundStyle(AppColor.subtleText)
                            .lineLimit(1)

                        WeekProgressBar(
                            progress: progress,
                            habitColor: habitColor
                        )
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: WeekGridLayout.cellSpacing) {
                ForEach(daysInWeek, id: \.self) { date in
                    WeekGridCell(
                        state: cellState(for: date),
                        habitColor: habitColor,
                        onTap: { onToggle(date) }
                    )
                }
            }
            .padding(8)
            .background(AppColor.surfaceMuted.opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
        }
        .padding(.leading, 20)
        .padding(.trailing, 14)
        .padding(.vertical, 14)
        .background(AppColor.surface)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(habitColor)
                .frame(width: 5)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(habitColor.opacity(0.12), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: AppColor.strongText.opacity(0.06), radius: 12, x: 0, y: 6)
        .padding(.vertical, 2)
    }

    private var subtitle: String {
        if habit.trackingKind == .quantity {
            return habit.targetPerSessionText
        }

        return habit.scheduleSummaryText
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

private struct WeekProgressPill: View {
    let completed: Int
    let target: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 11, weight: .semibold))

            Text("\(completed)/\(target)")
                .font(AppFont.formSectionText2)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}
