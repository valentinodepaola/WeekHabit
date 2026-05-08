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

    private var sortedHabits: [Habit] {
        plan.habits.sorted(by: { $0.createdAt > $1.createdAt })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                planSummary
            }
            .buttonStyle(PlanPressStyle())

            if isExpanded {
                expandedContent
                    .transition(
                        .asymmetric(
                            insertion: .opacity
                                .combined(with: .move(edge: .top)),
                            removal: .opacity
                        )
                    )
            }
        }
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Color(hex: "#e8dcc8"), lineWidth: 1)
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: isExpanded)
    }

    private var planSummary: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(plan.title)
                    .font(.system(size: 22, weight: .semibold, design: .serif).italic())
                    .foregroundStyle(AppColor.strongText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 8)

                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColor.subtleText)
            }

            Text(planSubtitle)
                .font(AppFont.captionApp)
                .fontWeight(.medium)
                .foregroundStyle(AppColor.mutedText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 13) {
                PlanTimelineBar(progress: timelineProgress)
                    .frame(height: 4)

                Text(timelineText)
                    .font(AppFont.formSectionText)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColor.mutedText)
                    .lineLimit(1)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .contentShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .overlay(Color(hex: "#e8dcc8"))

            if sortedHabits.isEmpty {
                PlanEmptyHabitRow()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sortedHabits.enumerated()), id: \.element.id) { index, habit in
                        PlanHabitRow(habit: habit) {
                            onHabitTap(habit)
                        }

                        if index < sortedHabits.count - 1 {
                            Divider()
                                .padding(.leading, 54)
                                .overlay(Color(hex: "#efe5d5"))
                        }
                    }
                }
                .background(Color(hex: "#fbf6ed"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    private var planSubtitle: String {
        guard let motivation = plan.motivation?.trimmingCharacters(in: .whitespacesAndNewlines),
              !motivation.isEmpty else {
            return plan.daysRemainingText
        }

        return motivation
    }

    private var timelineText: String {
        "\(elapsedPlanDays) / \(totalPlanDays) días"
    }

    private var totalPlanDays: Int {
        let start = AppCalendar.startOfDay(for: plan.startedAt)
        let end = AppCalendar.startOfDay(for: plan.endsAt)
        let days = AppCalendar.current.dateComponents([.day], from: start, to: end).day ?? 0
        return max(days + 1, 1)
    }

    private var elapsedPlanDays: Int {
        let start = AppCalendar.startOfDay(for: plan.startedAt)
        let today = AppCalendar.startOfDay(for: .now)
        let days = AppCalendar.current.dateComponents([.day], from: start, to: today).day ?? 0
        return min(max(days + 1, 1), totalPlanDays)
    }

    private var timelineProgress: Double {
        Double(elapsedPlanDays) / Double(totalPlanDays)
    }
}

private struct PlanTimelineBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColor.surfaceMuted)

                Capsule()
                    .fill(AppColor.strongText)
                    .frame(width: geo.size.width * CGFloat(min(max(progress, 0), 1)))
            }
        }
    }
}

private struct PlanHabitRow: View {
    let habit: Habit
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(habit.habitColor.opacity(0.14))
                        .frame(width: 34, height: 34)

                    Image(systemName: habit.iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(habit.habitColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title)
                        .font(AppFont.body2)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.strongText)
                        .lineLimit(1)

                    Text(cardSubtitle)
                        .font(AppFont.formSectionText2)
                        .foregroundStyle(AppColor.mutedText)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                PlanHabitWeekDots(habit: habit)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlanRowPressStyle())
    }

    private var cardSubtitle: String {
        let status = habit.isFinished() ? "terminado" : habit.scheduleSummaryText
        if habit.trackingKind == .quantity {
            return "\(status) · \(habit.targetPerSessionText)"
        }

        return status
    }
}

private struct PlanEmptyHabitRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColor.accent)

            Text("Sin hábitos asignados")
                .font(AppFont.body2)
                .foregroundStyle(AppColor.mutedText)

            Spacer()
        }
        .padding(14)
        .background(Color(hex: "#fbf6ed"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct PlanHabitWeekDots: View {
    let habit: Habit

    var body: some View {
        let completedWeekdays = habit.completedWeekdays()

        HStack(spacing: 4) {
            ForEach(Weekday.ordered) { weekday in
                Circle()
                    .fill(dotColor(weekday: weekday, completedWeekdays: completedWeekdays))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func dotColor(weekday: Weekday, completedWeekdays: Set<Weekday>) -> Color {
        if completedWeekdays.contains(weekday) {
            return AppColor.accent
        }

        if habit.scheduleKind == .timesPerWeek || habit.activeDaysOfWeek.contains(weekday) {
            return AppColor.subtleText.opacity(0.34)
        }

        return AppColor.subtleText.opacity(0.12)
    }
}

private struct PlanPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .opacity(configuration.isPressed ? 0.93 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct PlanRowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? AppColor.surfaceMuted.opacity(0.38) : Color.clear)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
