//
//  PlanAccordion.swift
//  WeekHabit
//

import SwiftUI

struct PlanAccordion: View {
    let plan: Plan
    let isExpanded: Bool
    let onToggle: () -> Void
    let onHabitTap: (Habit) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var categoryColor: Color { plan.displayCategory.color }
    private var progress: Double { plan.progress() }
    private var sortedHabits: [Habit] {
        plan.habits.sorted(by: { $0.createdAt > $1.createdAt })
    }

    var body: some View {
        VStack(spacing: 0) {
            planHeader

            if isExpanded {
                planHabits
                    .transition(
                        .asymmetric(
                            insertion: .opacity
                                .combined(with: .scale(scale: 0.97, anchor: .top))
                                .combined(with: .move(edge: .top)),
                            removal: .opacity
                                .combined(with: .scale(scale: 0.98, anchor: .top))
                        )
                    )
            }
        }
        .background(AppColor.surface)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(categoryColor)
                .frame(width: 5)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(categoryColor.opacity(isExpanded ? 0.24 : 0.12), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: AppColor.strongText.opacity(isExpanded ? 0.10 : 0.05), radius: isExpanded ? 16 : 8, x: 0, y: isExpanded ? 10 : 4)
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: isExpanded)
    }

    private var planHeader: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(categoryColor.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: plan.displayCategory.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(categoryColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.title)
                            .font(AppFont.body2)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColor.strongText)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text(plan.displayCategory.displayTitle)
                            Text("·")
                            Text(plan.daysRemainingText)
                        }
                        .font(AppFont.formSectionText2)
                        .foregroundStyle(AppColor.subtleText)
                        .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    ZStack {
                        Circle()
                            .fill(AppColor.surfaceMuted)
                            .frame(width: 30, height: 30)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppColor.subtleText)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(Int(progress * 100))%")
                            .font(AppFont.subtitle2)
                            .foregroundStyle(progressColor)
                            .monospacedDigit()

                        Text("de avance")
                            .font(AppFont.formSectionText2)
                            .foregroundStyle(AppColor.mutedText)

                        Spacer()

                        PlanMetricPill(
                            icon: "checklist",
                            text: "\(plan.habits.count) \(plan.habits.count == 1 ? "hábito" : "hábitos")",
                            color: categoryColor
                        )
                    }

                    PlanProgressBar(
                        progress: progress,
                        goal: plan.targetCompletionRate,
                        color: categoryColor
                    )
                    .frame(height: 7)
                }
            }
            .padding(.leading, 20)
            .padding(.trailing, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlanHeaderButtonStyle())
    }

    private var planHabits: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Hábitos del plan")
                    .font(AppFont.formSectionText)
                    .foregroundStyle(AppColor.mutedText)

                Spacer()

                Text(plan.daysRemainingText)
                    .font(AppFont.formSectionText2)
                    .foregroundStyle(AppColor.subtleText)
            }
            .padding(.horizontal, 16)

            if sortedHabits.isEmpty {
                PlanEmptyHabitRow(color: categoryColor)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sortedHabits.enumerated()), id: \.element.id) { index, habit in
                        PlanHabitRow(
                            habit: habit,
                            color: categoryColor
                        ) {
                            onHabitTap(habit)
                        }

                        if index < sortedHabits.count - 1 {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(AppColor.surfaceMuted.opacity(0.58))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
                .padding(.horizontal, 12)
            }
        }
        .padding(.top, 2)
        .padding(.bottom, 14)
    }

    private var progressColor: Color {
        plan.meetsGoal() ? AppColor.accent : AppColor.strongText
    }
}

private struct PlanHabitRow: View {
    let habit: Habit
    let color: Color
    let onTap: () -> Void

    private var category: HabitCategory {
        habit.displayCategory
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.16))
                        .frame(width: 36, height: 36)

                    Image(systemName: category.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(category.color)
                }

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(habit.title)
                            .font(AppFont.body2)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColor.strongText)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10, weight: .semibold))
                            Text("\(habit.currentStreak())")
                                .font(AppFont.formSectionText2)
                                .fontWeight(.medium)
                                .monospacedDigit()
                        }
                        .foregroundStyle(color)
                    }

                    HStack(spacing: 10) {
                        Text(cardSubtitle)
                            .font(AppFont.formSectionText2)
                            .foregroundStyle(AppColor.subtleText)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        PlanHabitWeekDots(habit: habit)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlanHabitRowButtonStyle())
    }

    private var cardSubtitle: String {
        let status = habit.isFinished() ? "terminado" : habit.scheduleSummaryText
        if habit.trackingKind == .quantity {
            return "\(category.displayTitle) · \(status) · \(habit.targetPerSessionText)"
        }

        return "\(category.displayTitle) · \(status)"
    }
}

private struct PlanEmptyHabitRow: View {
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)

            Text("Sin hábitos asignados")
                .font(AppFont.body2)
                .foregroundStyle(AppColor.subtleText)

            Spacer()
        }
        .padding(14)
        .background(AppColor.surfaceMuted.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
        .padding(.horizontal, 12)
    }
}

private struct PlanHabitWeekDots: View {
    let habit: Habit

    var body: some View {
        let completedWeekdays = habit.completedWeekdays()

        HStack(spacing: 4) {
            ForEach(Weekday.ordered) { weekday in
                PlanHabitDot(
                    isCompleted: completedWeekdays.contains(weekday),
                    isActive: habit.scheduleKind == .timesPerWeek || habit.activeDaysOfWeek.contains(weekday)
                )
            }
        }
    }
}

private struct PlanHabitDot: View {
    let isCompleted: Bool
    let isActive: Bool

    var body: some View {
        Circle()
            .fill(fillColor)
            .frame(width: 7, height: 7)
    }

    private var fillColor: Color {
        if isCompleted {
            return AppColor.accent
        }

        if isActive {
            return AppColor.subtleText.opacity(0.34)
        }

        return AppColor.subtleText.opacity(0.12)
    }
}

private struct PlanMetricPill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))

            Text(text)
                .font(AppFont.formSectionText2)
                .fontWeight(.medium)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

private struct PlanProgressBar: View {
    let progress: Double
    let goal: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColor.surfaceMuted)

                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(min(progress, 1)))

                Rectangle()
                    .fill(AppColor.strongText.opacity(0.28))
                    .frame(width: 1.5, height: geo.size.height + 3)
                    .offset(x: geo.size.width * CGFloat(goal) - 0.75)
            }
        }
    }
}

private struct PlanHeaderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

private struct PlanHabitRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? AppColor.surface.opacity(0.65) : Color.clear)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
