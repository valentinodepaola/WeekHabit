//
//  TodayHabitComponent.swift
//  WeekHabit
//

import SwiftUI

struct TodayHabitComponent: View {
    let habit: Habit
    let isCompleted: Bool
    var isSkipped: Bool = false
    var activeExperiment: HabitExperiment?
    var referenceDate: Date = .now
    var onSlip: (() -> Void)? = nil
    let onToggle: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack(alignment: .center, spacing: AppSpacing.m) {
                completeToggle

                textContent

                Spacer(minLength: AppSpacing.s)

                iconColumn
            }

            if shouldShowSlipAction {
                slipAction
                    .padding(.leading, 34 + AppSpacing.m)
            }
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.vertical, AppSpacing.l)
        .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .strokeBorder(isSkipped ? habit.habitColor.opacity(0.38) : AppColor.divider, lineWidth: 1)
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
                if isSkipped {
                    Text("Descanso intencional")
                        .font(AppFont.label)
                        .foregroundStyle(habit.habitColor)
                        .lineLimit(1)
                } else if let trimmedCue {
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
        ZStack {
            Circle()
                .fill(habit.habitColor.opacity(0.14))

            Image(systemName: habit.iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(habit.habitColor)
        }
        .frame(width: 38, height: 38)
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
                    .fill(toggleFill)
                    .frame(width: 34, height: 34)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                            .strokeBorder(
                                isCompleted || isSkipped ? habit.habitColor : AppColor.divider,
                                lineWidth: 1
                            )
                    }
                if isCompleted {
                    Image(systemName: habit.isBreakHabit ? "xmark" : "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: isCompleted)
                } else if isSkipped {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(habit.habitColor)
                        .symbolEffect(.pulse, value: isSkipped)
                }
            }
            .scaleEffect(isCompleted ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(AppMotion.respectful(AppMotion.celebration, reduceMotion), value: isCompleted || isSkipped)
        .accessibilityLabel(toggleAccessibilityLabel)
    }

    private var slipAction: some View {
        Button {
            onSlip?()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .semibold))

                Text("Registrar slip")
                    .font(AppFont.label)
            }
            .foregroundStyle(AppColor.warning)
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.s)
            .background(AppColor.warning.opacity(0.10))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(AppColor.warning.opacity(0.24), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Registrar slip para \(habit.title)")
    }

    private func handleToggle() {
        if !isCompleted && !isSkipped {
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

    private var shouldShowSlipAction: Bool {
        habit.isBreakHabit && !isCompleted && !isSkipped && onSlip != nil
    }

    private var scheduleFallbackText: String {
        if isSkipped {
            return "Descanso intencional"
        }
        if habit.isBreakHabit && !isCompleted {
            return "Lo evité hoy"
        }
        if habit.trackingKind == .quantity {
            return habit.targetPerSessionText
        }
        return "Diario"
    }

    private var toggleFill: Color {
        if isCompleted {
            return habit.habitColor
        }
        if isSkipped {
            return habit.habitColor.opacity(0.10)
        }
        return AppColor.bgElevated
    }

    private var toggleAccessibilityLabel: String {
        if isCompleted {
            return "Desmarcar hábito"
        }
        if isSkipped {
            return "Marcar hábito"
        }
        return "Marcar hábito"
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
