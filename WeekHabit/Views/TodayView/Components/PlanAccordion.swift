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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var planColor: Color { AppColor.accent }
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
        .background(AppColor.bgElevated)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(planColor)
                .frame(width: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .stroke(planColor.opacity(isExpanded ? 0.24 : 0.12), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(isExpanded ? .medium : .low)
        .animation(AppMotion.respectful(AppMotion.smooth, reduceMotion), value: isExpanded)
    }

    private var planHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack(spacing: AppSpacing.m) {
                Button(action: onToggle) {
                    HStack(spacing: AppSpacing.m) {
                        ZStack {
                            Circle()
                                .fill(planColor.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "target")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(planColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(plan.title)
                                .font(AppFont.bodyEmphasis)
                                .foregroundStyle(AppColor.textPrimary)
                                .lineLimit(1)
                            Text(plan.daysRemainingText)
                                .font(AppFont.label)
                                .foregroundStyle(AppColor.textTertiary)
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(PlanHeaderButtonStyle())

                Spacer(minLength: AppSpacing.s)

                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .fill(AppColor.bgSunken)
                            .frame(width: 30, height: 30)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppColor.textSecondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
                .buttonStyle(PlanHeaderButtonStyle())
            }

            Button(action: onToggle) {
                VStack(alignment: .leading, spacing: AppSpacing.s) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(Int(progress * 100))%")
                            .font(AppFont.bodyEmphasis)
                            .foregroundStyle(progressColor)
                            .monospacedDigit()
                        Text("de avance")
                            .font(AppFont.label)
                            .foregroundStyle(AppColor.textSecondary)
                        Spacer()
                        PlanMetricPill(
                            icon: "checklist",
                            text: "\(plan.habits.count) \(plan.habits.count == 1 ? "hábito" : "hábitos")",
                            color: planColor
                        )
                    }

                    WHProgressBar(
                        progress: progress,
                        progressColor: planColor,
                        height: 7,
                        goalMarker: plan.targetCompletionRate
                    )
                }
            }
            .buttonStyle(PlanHeaderButtonStyle())
        }
        .padding(.leading, AppSpacing.xl)
        .padding(.trailing, AppSpacing.l)
        .padding(.vertical, AppSpacing.l)
    }

    private var planHabits: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack {
                Text("Hábitos del plan")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                Text(plan.daysRemainingText)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
            }
            .padding(.horizontal, AppSpacing.l)

            if sortedHabits.isEmpty {
                PlanEmptyHabitRow(color: planColor)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sortedHabits.enumerated()), id: \.element.id) { index, habit in
                        PlanHabitRow(habit: habit, color: planColor) {
                            onHabitTap(habit)
                        }
                        if index < sortedHabits.count - 1 {
                            Divider()
                                .overlay(AppColor.divider)
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(AppColor.bgSunken.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
                .padding(.horizontal, AppSpacing.m)
            }
        }
        .padding(.top, 2)
        .padding(.bottom, AppSpacing.m)
    }

    private var progressColor: Color {
        plan.meetsGoal() ? AppColor.success : AppColor.textPrimary
    }
}

private struct PlanHabitRow: View {
    let habit: Habit
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: AppSpacing.m) {
                ZStack {
                    Circle()
                        .fill(habit.habitColor.opacity(0.16))
                        .frame(width: 36, height: 36)
                    Image(systemName: habit.iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(habit.habitColor)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(alignment: .firstTextBaseline, spacing: AppSpacing.s) {
                        Text(habit.title)
                            .font(AppFont.bodyEmphasis)
                            .foregroundStyle(AppColor.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: AppSpacing.s)
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10, weight: .semibold))
                            Text("\(streakCount)")
                                .font(AppFont.label)
                                .monospacedDigit()
                        }
                        .foregroundStyle(streakColor)
                    }

                    HStack(spacing: AppSpacing.s) {
                        Text(cardSubtitle)
                            .font(AppFont.label)
                            .foregroundStyle(AppColor.textTertiary)
                            .lineLimit(1)
                        Spacer(minLength: AppSpacing.s)
                        PlanHabitWeekDots(habit: habit)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.m)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlanHabitRowButtonStyle())
    }

    private var cardSubtitle: String {
        let status = habit.isFinished() ? "terminado" : habit.scheduleSummaryText
        if habit.trackingKind == .quantity {
            return "\(status) · \(habit.targetPerSessionText)"
        }
        return status
    }

    private var streakCount: Int {
        habit.currentStreak()
    }

    private var streakColor: Color {
        streakCount > 0 ? AppColor.warning : AppColor.textTertiary
    }
}

private struct PlanEmptyHabitRow: View {
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            Image(systemName: "plus.circle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
            Text("Sin hábitos asignados")
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
        }
        .padding(AppSpacing.m)
        .background(AppColor.bgSunken.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .padding(.horizontal, AppSpacing.m)
    }
}

private struct PlanHabitWeekDots: View {
    let habit: Habit

    var body: some View {
        let completedWeekdays = habit.completedWeekdays()

        HStack(spacing: AppSpacing.xs) {
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
        if isCompleted { return AppColor.accent }
        if isActive { return AppColor.textTertiary.opacity(0.5) }
        return AppColor.textTertiary.opacity(0.18)
    }
}

private struct PlanMetricPill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(AppFont.label)
        }
        .foregroundStyle(color)
        .padding(.horizontal, AppSpacing.s)
        .padding(.vertical, AppSpacing.xs)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

private struct PlanHeaderButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(AppMotion.respectful(AppMotion.linearOut, reduceMotion), value: configuration.isPressed)
    }
}

private struct PlanHabitRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? AppColor.bgElevated.opacity(0.6) : Color.clear)
            .animation(AppMotion.linearOut, value: configuration.isPressed)
    }
}
