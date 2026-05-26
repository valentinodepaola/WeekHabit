//
//  TodayHabitComponent.swift
//  WeekHabit
//

import SwiftUI

struct TodayHabitComponent: View {
    let habit: Habit
    let isCompleted: Bool
    var isMinimumCompleted: Bool = false
    var isSkipped: Bool = false
    var activeExperiment: HabitExperiment?
    var referenceDate: Date = .now
    var onUrge: (() -> Void)? = nil
    var onSlip: (() -> Void)? = nil
    var onMinimum: (() -> Void)? = nil
    let onToggle: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressing: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack(alignment: .center, spacing: AppSpacing.m) {
                completeToggle

                textContent

                Spacer(minLength: AppSpacing.s)

                iconColumn
            }

            if shouldShowBreakActions {
                breakActions
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
                if isMinimumCompleted, let trimmedMinimumTitle {
                    Text("Versión mínima · \(trimmedMinimumTitle)")
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                } else if isSkipped {
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

    @ViewBuilder
    private var completeToggle: some View {
        if hasMinimumAction {
            Menu {
                Button {
                    handleMinimum()
                } label: {
                    Label("Hice la mínima", systemImage: "checkmark.circle")
                }
            } label: {
                toggleVisual
            } primaryAction: {
                handleToggle()
            }
            .buttonStyle(.plain)
            .simultaneousGesture(pressGesture)
            .animation(AppMotion.respectful(AppMotion.celebration, reduceMotion), value: isCompleted || isMinimumCompleted || isSkipped)
            .accessibilityLabel(toggleAccessibilityLabel)
        } else {
            Button(action: handleToggle) {
                toggleVisual
            }
            .buttonStyle(.plain)
            .simultaneousGesture(pressGesture)
            .animation(AppMotion.respectful(AppMotion.celebration, reduceMotion), value: isCompleted || isMinimumCompleted || isSkipped)
            .accessibilityLabel(toggleAccessibilityLabel)
        }
    }

    private var toggleVisual: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                .fill(toggleFill)
                .frame(width: 34, height: 34)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                        .strokeBorder(toggleBorderColor, lineWidth: 1)
                }
            if isCompleted {
                Image(systemName: habit.isBreakHabit ? "xmark" : "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: isCompleted)
            } else if isMinimumCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: isMinimumCompleted)
            } else if isSkipped {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(habit.habitColor)
                    .symbolEffect(.pulse, value: isSkipped)
            }
        }
        .scaleEffect(toggleScale)
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !reduceMotion, !isPressing else { return }
                withAnimation(AppMotion.respectful(AppMotion.snap, reduceMotion)) {
                    isPressing = true
                }
            }
            .onEnded { _ in
                guard !reduceMotion else {
                    isPressing = false
                    return
                }
                withAnimation(AppMotion.respectful(AppMotion.snap, reduceMotion)) {
                    isPressing = false
                }
            }
    }

    private var breakActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppSpacing.s) {
                breakActionButtons
            }

            VStack(alignment: .leading, spacing: AppSpacing.s) {
                breakActionButtons
            }
        }
    }

    @ViewBuilder
    private var breakActionButtons: some View {
        if let onUrge {
            Button(action: onUrge) {
                actionPill(
                    title: "Tuve el impulso",
                    icon: "waveform.path.ecg",
                    color: habit.habitColor
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Registrar impulso de \(habit.title)")
        }

        if let onSlip {
            Button(action: onSlip) {
                actionPill(
                    title: "Registrar slip",
                    icon: "arrow.counterclockwise",
                    color: AppColor.warning
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Registrar slip para \(habit.title)")
        }
    }

    private func actionPill(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))

            Text(title)
                .font(AppFont.label)
                .lineLimit(1)
        }
        .foregroundStyle(color)
        .padding(.horizontal, AppSpacing.m)
        .padding(.vertical, AppSpacing.s)
        .background(color.opacity(0.10))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .strokeBorder(color.opacity(0.24), lineWidth: 1)
        }
    }

    private func handleToggle() {
        // Para hábitos de cantidad, el toggle solo abre el sheet; la háptica
        // de cierre se dispara cuando se guarda la cantidad en upsertQuantityEntry.
        let opensQuantitySheet = habit.trackingKind == .quantity
        let willCloseLoop = !isCompleted && !isMinimumCompleted && !opensQuantitySheet
        if willCloseLoop {
            AppHaptics.play(habit.isBreakHabit ? .urgeAvoided : .habitCompleted)
        }
        onToggle()
    }

    private func handleMinimum() {
        AppHaptics.play(.habitCompleted)
        onMinimum?()
    }

    // MARK: - Computed

    private var trimmedCue: String? {
        guard let cue = habit.cue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !cue.isEmpty else {
            return nil
        }
        return cue
    }

    private var trimmedMinimumTitle: String? {
        guard let title = habit.minimumViableTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty else {
            return nil
        }
        return title
    }

    private var hasMinimumAction: Bool {
        trimmedMinimumTitle != nil && !isCompleted && !isMinimumCompleted && !isSkipped && onMinimum != nil
    }

    private var shouldShowScheduleFallback: Bool {
        trimmedCue == nil && !isMinimumCompleted
    }

    private var shouldShowBreakActions: Bool {
        habit.isBreakHabit && !isCompleted && !isSkipped && (onSlip != nil || onUrge != nil)
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
        if isMinimumCompleted {
            return habit.habitColor.opacity(0.55)
        }
        if isSkipped {
            return habit.habitColor.opacity(0.10)
        }
        return AppColor.bgElevated
    }

    private var toggleBorderColor: Color {
        if isCompleted || isMinimumCompleted || isSkipped {
            return habit.habitColor
        }
        return AppColor.divider
    }

    private var toggleScale: CGFloat {
        guard !reduceMotion else { return 1.0 }
        if isPressing {
            return 0.92
        }
        return isCompleted || isMinimumCompleted ? 1.04 : 1.0
    }

    private var toggleAccessibilityLabel: String {
        if isCompleted {
            return "Desmarcar hábito"
        }
        if isMinimumCompleted {
            return "Marcar hábito completo"
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
