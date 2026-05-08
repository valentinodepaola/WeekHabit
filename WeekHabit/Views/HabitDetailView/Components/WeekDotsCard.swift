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
        VStack(alignment: .leading, spacing: 14) {
            Text("ESTA SEMANA")
                .font(AppFont.formSectionText)
                .foregroundStyle(AppColor.mutedText)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                ForEach(Array(Weekday.ordered.enumerated()), id: \.element.id) { index, weekday in
                    VStack(spacing: 7) {
                        Text(weekday.oneLetterName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppColor.subtleText)
                            .frame(width: 30)

                        WeekDot(
                            isCompleted: habit.isCompleted(on: date(for: index)),
                            isActive: habit.isLoggable(on: date(for: index)),
                            color: habit.habitColor
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Color(hex: "#e8dcc8"), lineWidth: 1)
        }
    }

    private func date(for dayIndex: Int) -> Date {
        AppCalendar.current.date(byAdding: .day, value: dayIndex, to: weekStart) ?? weekStart
    }
}

private struct WeekDot: View {
    let isCompleted: Bool
    let isActive: Bool
    let color: Color

    private let size: CGFloat = 30

    var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
                .overlay {
                    Circle()
                        .stroke(borderColor, lineWidth: 1.2)
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
            return color
        }

        if isActive {
            return Color(hex: "#ece2cc")
        }

        return AppColor.subtleText.opacity(0.08)
    }

    private var borderColor: Color {
        if isCompleted && isActive {
            return color
        }

        if isActive {
            return color
        }

        return AppColor.subtleText.opacity(0.25)
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
    .background(AppColor.bgLight)
}
