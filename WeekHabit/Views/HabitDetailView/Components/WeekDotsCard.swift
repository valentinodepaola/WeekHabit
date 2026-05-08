//
//  WeekDotsCard.swift
//  WeekHabit
//

import SwiftUI

struct WeekDotsCard: View {
    let habit: Habit
    var referenceDate: Date = .now

    private var weekStart: Date {
        AppCalendar.weekRange(containing: referenceDate).lowerBound
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            Text("ESTA SEMANA")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(0.6)

            HStack(spacing: AppSpacing.s) {
                ForEach(Array(Weekday.ordered.enumerated()), id: \.element.id) { index, weekday in
                    let dayDate = date(for: index)
                    VStack(spacing: AppSpacing.s) {
                        Text(weekday.oneLetterName)
                            .font(AppFont.label)
                            .foregroundStyle(AppColor.textTertiary)
                            .frame(width: 30)

                        WeekDot(
                            isCompleted: habit.isCompleted(on: dayDate),
                            isActive: habit.isLoggable(on: dayDate),
                            isRetroactive: isRetroactive(on: dayDate),
                            color: habit.habitColor
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.l)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(.low)
    }

    private func date(for dayIndex: Int) -> Date {
        AppCalendar.current.date(byAdding: .day, value: dayIndex, to: weekStart) ?? weekStart
    }

    private func isRetroactive(on date: Date) -> Bool {
        let entries = habit.entries.filter { AppCalendar.isSameDay($0.date, date) }
        guard !entries.isEmpty else { return false }
        return entries.allSatisfy { $0.source == .manual }
    }
}

private struct WeekDot: View {
    let isCompleted: Bool
    let isActive: Bool
    let isRetroactive: Bool
    let color: Color

    private let size: CGFloat = 30

    var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
                .overlay {
                    Circle()
                        .strokeBorder(borderColor, style: borderStyle)
                }

            if isCompleted && isActive {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
    }

    private var fillColor: Color {
        if isCompleted && isActive {
            return isRetroactive ? color.opacity(0.7) : color
        }
        if isActive {
            return AppColor.bgSunken
        }
        return AppColor.divider.opacity(0.4)
    }

    private var borderColor: Color {
        if isCompleted && isActive { return color }
        if isActive { return color.opacity(0.45) }
        return AppColor.divider
    }

    private var borderStyle: StrokeStyle {
        if isCompleted && isRetroactive {
            return StrokeStyle(lineWidth: 1.2, dash: [2.5, 2])
        }
        return StrokeStyle(lineWidth: 1.2)
    }
}

#Preview {
    WeekDotsCard(
        habit: Habit(
            title: "Caminar",
            iconName: "figure.walk",
            colorHex: "#7fa774",
            targetDaysPerWeek: 3,
            activeDaysOfWeek: [.monday, .wednesday, .friday]
        )
    )
    .padding()
    .background(AppColor.bgCanvas)
}
