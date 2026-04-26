//
//  HabitCard.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 25/04/26.
//

import SwiftUI

struct HabitCard: View {

    var habit: Habit
    var referenceDate: Date = .now
    var onTap: () -> Void
    private var category: HabitCategory {
        habit.displayCategory
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    IconComponent(
                        icon: category.icon,
                        color: category.color
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.title)
                            .font(AppFont.body2)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColor.strongText)
                            .lineLimit(1)

                        Text("\(category.displayTitle) · meta \(habit.targetDaysPerWeek)/sem")
                            .font(AppFont.formSectionText2)
                            .foregroundStyle(AppColor.subtleText)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    HStack(spacing: 4) {
                        Image(systemName: "flame")
                            .font(.system(size: 12, weight: .semibold))
                        Text("\(habit.currentStreak(reference: referenceDate))")
                            .font(AppFont.formSectionText2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(AppColor.accent)
                    .padding(.top, 4)
                }

                WeekProgressDots(
                    habit: habit,
                    referenceDate: referenceDate
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(HabitCardButtonStyle())
        .padding(.horizontal)
    }
}

private struct WeekProgressDots: View {
    var habit: Habit
    var referenceDate: Date

    private var completedWeekdays: Set<Weekday> {
        let week = AppCalendar.weekRange(containing: referenceDate)

        return Set(
            habit.entries
                .filter { week.contains($0.date) }
                .map { AppCalendar.weekday(of: $0.date) }
        )
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Weekday.ordered) { weekday in
                VStack(spacing: 5) {
                    Text(weekday.oneLetterName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppColor.subtleText)
                        .frame(width: 22)

                    WeekProgressDot(
                        isCompleted: completedWeekdays.contains(weekday),
                        isActive: habit.activeDaysOfWeek.contains(weekday)
                    )
                }
            }
        }
    }
}

private struct WeekProgressDot: View {
    var isCompleted: Bool
    var isActive: Bool
    private let size = CGSize(width: 20, height: 26)

    var body: some View {
        ZStack {
            Capsule()
                .fill(fillColor)
                .frame(width: size.width, height: size.height)
                .overlay {
                    Capsule()
                        .stroke(borderColor, lineWidth: 1)
                }

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private var fillColor: Color {
        if isCompleted {
            return AppColor.accent
        }

        if isActive {
            return AppColor.surface
        }

        return AppColor.surfaceMuted.opacity(0.45)
    }

    private var borderColor: Color {
        if isCompleted {
            return AppColor.accent
        }

        if isActive {
            return AppColor.subtleText.opacity(0.28)
        }

        return AppColor.subtleText.opacity(0.12)
    }
}

private struct HabitCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    HabitCard(
        habit: Habit(
            title: "Tender cama",
            category: .health,
            targetDaysPerWeek: 3,
            activeDaysOfWeek: [.friday, .saturday, .sunday]
        ),
        onTap: {}
    )
}
