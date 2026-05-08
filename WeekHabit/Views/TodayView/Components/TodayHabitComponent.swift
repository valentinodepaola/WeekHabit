//
//  TodayHabitComponent.swift
//  WeekHabit
//

import SwiftUI

struct TodayHabitComponent: View {
    let habit: Habit
    let isCompleted: Bool
    var activeExperiment: HabitExperiment?
    var referenceDate: Date = .now
    let onToggle: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.m) {
            completeToggle

            textContent

            Spacer(minLength: AppSpacing.s)

            iconColumn
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.vertical, AppSpacing.l)
        .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .strokeBorder(AppColor.divider, lineWidth: 1)
        }
        .appElevation(.low)
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(habit.title)
                .font(AppFont.bodyEmphasis)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                if let trimmedCue {
                    cueLine(trimmedCue)
                }

                if let experimentSubtitle {
                    Text(experimentSubtitle)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.info)
                        .lineLimit(2)
                } else if shouldShowScheduleFallback {
                    Text(scheduleFallbackText)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var iconColumn: some View {
        VStack(alignment: .trailing, spacing: AppSpacing.xs) {
            iconBadge

            if streakCount > 0 {
                streakIndicator
            }
        }
        .frame(width: 44, alignment: .trailing)
    }

    private var iconBadge: some View {
        Image(systemName: habit.iconName)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(habit.habitColor)
            .frame(width: 36, height: 36)
            .accessibilityHidden(true)
    }

    private func cueLine(_ cue: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(habit.habitColor)

            Text(cue)
                .font(AppFont.label)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(2)
        }
        .padding(.top, 1)
    }

    private var streakIndicator: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "flame.fill")
                .font(.system(size: 10, weight: .semibold))

            Text("\(streakCount)")
                .font(AppFont.micro)
                .monospacedDigit()
        }
        .foregroundStyle(streakColor)
        .accessibilityLabel(streakAccessibilityLabel)
        .opacity(streakCount == 0 ? 0.5 : 1)
    }

    private var completeToggle: some View {
        Button(action: handleToggle) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                    .fill(isCompleted ? habit.habitColor : AppColor.bgElevated)
                    .frame(width: 34, height: 34)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                            .strokeBorder(
                                isCompleted ? habit.habitColor : AppColor.divider,
                                lineWidth: 1
                            )
                    }
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .scaleEffect(isCompleted ? 1.0 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(AppMotion.respectful(AppMotion.celebration, reduceMotion), value: isCompleted)
        .accessibilityLabel(isCompleted ? "Desmarcar hábito" : "Marcar hábito")
    }

    private func handleToggle() {
        if !isCompleted {
            AppHaptics.play(.habitCompleted)
        }
        onToggle()
    }

    // MARK: - Computed

    private var trimmedCue: String? {
        guard let cue = habit.cue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !cue.isEmpty else {
            return nil
        }
        return cue
    }

    private var shouldShowScheduleFallback: Bool {
        trimmedCue == nil
    }

    private var scheduleFallbackText: String {
        if habit.trackingKind == .quantity {
            return habit.targetPerSessionText
        }
        return "Diario"
    }

    private var streakCount: Int {
        habit.displayStreak(reference: referenceDate)
    }

    private var streakAccessibilityLabel: String {
        streakCount == 0
            ? "Listo para volver a empezar"
            : "\(streakCount) días seguidos"
    }

    private var streakColor: Color {
        streakCount > 0 ? AppColor.warning : AppColor.textTertiary
    }

    private var experimentSubtitle: String? {
        guard let activeExperiment else { return nil }

        if activeExperiment.needsReview(reference: referenceDate) {
            return "Prueba lista para revisar en Insights"
        }

        if let suggestedHourText = activeExperiment.suggestedHourText {
            return "Prueba · \(suggestedHourText)"
        }

        return "Prueba activa · \(activeExperiment.daySummary)"
    }
}
