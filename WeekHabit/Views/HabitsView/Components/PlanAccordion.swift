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

    var body: some View {
        VStack(spacing: 0) {
            planHeader

            if isExpanded {
                planHabits
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var planHeader: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: plan.displayCategory.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(categoryColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.title)
                        .font(AppFont.body2)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.strongText)
                        .lineLimit(1)

                    Text(plan.daysRemainingText)
                        .font(AppFont.formSectionText2)
                        .foregroundStyle(AppColor.subtleText)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(plan.progress() * 100))%")
                        .font(AppFont.formSectionText)
                        .fontWeight(.bold)
                        .foregroundStyle(progressColor)
                        .monospacedDigit()

                    PlanProgressBar(
                        progress: plan.progress(),
                        goal: plan.targetCompletionRate,
                        color: categoryColor
                    )
                    .frame(width: 64, height: 4)
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.subtleText)
                    .padding(.leading, 4)
            }
            .padding(16)
        }
        .buttonStyle(PlanHeaderButtonStyle())
    }

    private var planHabits: some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.horizontal, 16)

            if plan.habits.isEmpty {
                Text("Sin hábitos asignados")
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.subtleText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(plan.habits.sorted(by: { $0.createdAt > $1.createdAt })) { habit in
                    HabitCard(habit: habit, includesHorizontalPadding: false) {
                        onHabitTap(habit)
                    }
                    .padding(.horizontal, 16)
                }
            }

            Spacer().frame(height: 8)
        }
    }

    private var progressColor: Color {
        plan.meetsGoal() ? AppColor.accent : AppColor.subtleText
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

                // Marcador de meta
                Rectangle()
                    .fill(AppColor.mutedText.opacity(0.5))
                    .frame(width: 1.5, height: geo.size.height)
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
