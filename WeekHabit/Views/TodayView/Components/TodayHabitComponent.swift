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
    var onOpenDetail: (() -> Void)? = nil
    let onToggle: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressing: Bool = false

    /// Fila de un hábito dentro de su grupo en Hoy. El fondo, las esquinas y el separador
    /// los pone el grupo (`todayGroupedRow`); aquí solo va el contenido.
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(alignment: .center, spacing: AppSpacing.xs) {
                completeToggle

                HStack(spacing: AppSpacing.m) {
                    textContent

                    Spacer(minLength: AppSpacing.s)

                    iconBadge
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    onOpenDetail?()
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Ver detalle")
            }

            if hasMinimumAction {
                minimumAction
                    .padding(.leading, secondaryActionLeadingPadding)
            }

            if shouldShowBreakActions {
                breakActions
                    .padding(.leading, secondaryActionLeadingPadding)
            }
        }
        .padding(.leading, AppSpacing.xs)
        .padding(.trailing, AppSpacing.m)
        .padding(.vertical, AppSpacing.s)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(habit.title)
                .font(AppFont.bodyEmphasis)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)

            // Una sola línea: lo que más dice del día y, al final, la racha.
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
                subtitle

                if streakCount > 0 {
                    streakIndicator
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var subtitle: some View {
        if isMinimumCompleted, let trimmedMinimumTitle {
            subtitleText("Versión mínima · \(trimmedMinimumTitle)", color: AppColor.textSecondary)
        } else if isSkipped {
            subtitleText("Descanso intencional", color: habit.habitColor)
        } else if let experimentSubtitle {
            subtitleText(experimentSubtitle, color: AppColor.info)
        } else if let quantityProgressText {
            subtitleText(quantityProgressText, color: AppColor.textSecondary)
        } else if let trimmedCue {
            cueLine(trimmedCue)
        } else {
            subtitleText(scheduleFallbackText, color: AppColor.textSecondary)
        }
    }

    private func subtitleText(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppFont.label)
            .foregroundStyle(color)
            .lineLimit(1)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(habit.habitColor.opacity(0.14))

            Image(systemName: habit.iconName)
                .font(AppFont.iconSmall)
                .foregroundStyle(habit.habitColor)
        }
        .frame(width: 30, height: 30)
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
                .lineLimit(1)
        }
    }

    private var streakIndicator: some View {
        HStack(spacing: AppSpacing.xxs) {
            Text("·")
                .accessibilityHidden(true)

            Image(systemName: "flame.fill")
                .font(.system(size: 10, weight: .semibold))

            Text("\(streakCount)")
                .monospacedDigit()
        }
        .font(AppFont.label)
        .foregroundStyle(AppColor.warning)
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(streakAccessibilityLabel)
    }

    private var completeToggle: some View {
        Button(action: handleToggle) {
            toggleVisual
        }
        .buttonStyle(.plain)
        .simultaneousGesture(pressGesture)
        .animation(AppMotion.respectful(AppMotion.celebration, reduceMotion), value: isCompleted || isMinimumCompleted || isSkipped)
        .accessibilityLabel(toggleAccessibilityLabel)
    }

    private var toggleVisual: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.xs, style: .continuous)
                .fill(toggleFill)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.xs, style: .continuous)
                        .strokeBorder(toggleBorderColor, lineWidth: 1.5)
                }
                .overlay {
                    // Avance de un hábito de cantidad: el borde se llena con el color del hábito.
                    if quantityProgress > 0, quantityProgress < 1 {
                        ClockwiseRoundedSquare(cornerRadius: AppRadius.xs)
                            .inset(by: 0.75)
                            .trim(from: 0, to: quantityProgress)
                            .stroke(habit.habitColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    }
                }
            if isCompleted {
                Image(systemName: habit.isBreakHabit ? "xmark" : "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: isCompleted)
            } else if isMinimumCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: isMinimumCompleted)
            } else if isSkipped {
                Image(systemName: "pause.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(habit.habitColor)
                    .symbolEffect(.pulse, value: isSkipped)
            }
        }
        .frame(width: 26, height: 26)
        .scaleEffect(toggleScale)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }

    private var minimumAction: some View {
        Button(action: handleMinimum) {
            actionPill(
                title: "Hice la mínima",
                icon: "checkmark.circle",
                color: habit.habitColor
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Marcar versión mínima de \(habit.title)")
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

    private var shouldShowBreakActions: Bool {
        habit.isBreakHabit && !isCompleted && !isSkipped && (onSlip != nil || onUrge != nil)
    }

    private var secondaryActionLeadingPadding: CGFloat {
        44 + AppSpacing.xs
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
            return habit.habitColor.opacity(0.12)
        }
        return Color.clear
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
        IdentityReinforcementCopy.streakAccessibility(
            for: habit,
            streakCount: streakCount
        )
    }

    private var quantityProgressText: String? {
        habit.todayQuantityProgressText(on: referenceDate)
    }

    private var quantityProgress: Double {
        habit.todayQuantityProgress(on: referenceDate)
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

/// Contorno de la casilla que empieza arriba al centro y avanza como las manecillas, para que
/// el avance de un hábito de cantidad se lea como un reloj al recortarlo con `trim`.
private struct ClockwiseRoundedSquare: InsettableShape {
    let cornerRadius: CGFloat
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let radius = min(cornerRadius, r.width / 2, r.height / 2)
        var path = Path()
        path.move(to: CGPoint(x: r.midX, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX - radius, y: r.minY))
        path.addArc(tangent1End: CGPoint(x: r.maxX, y: r.minY), tangent2End: CGPoint(x: r.maxX, y: r.minY + radius), radius: radius)
        path.addLine(to: CGPoint(x: r.maxX, y: r.maxY - radius))
        path.addArc(tangent1End: CGPoint(x: r.maxX, y: r.maxY), tangent2End: CGPoint(x: r.maxX - radius, y: r.maxY), radius: radius)
        path.addLine(to: CGPoint(x: r.minX + radius, y: r.maxY))
        path.addArc(tangent1End: CGPoint(x: r.minX, y: r.maxY), tangent2End: CGPoint(x: r.minX, y: r.maxY - radius), radius: radius)
        path.addLine(to: CGPoint(x: r.minX, y: r.minY + radius))
        path.addArc(tangent1End: CGPoint(x: r.minX, y: r.minY), tangent2End: CGPoint(x: r.minX + radius, y: r.minY), radius: radius)
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> ClockwiseRoundedSquare {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}
