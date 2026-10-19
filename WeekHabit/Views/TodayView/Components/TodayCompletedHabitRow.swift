//
//  TodayCompletedHabitRow.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 06/06/26.
//

import SwiftUI

struct TodayCompletedHabitRow: View {
    let habit: Habit
    /// Lo que va a la derecha: la hora, o por qué está en completados.
    let detail: TodayCompletionDetail
    var isMinimumCompleted: Bool = false
    /// Presente cuando el hábito descansa porque ya cumplió su meta semanal: el toque muestra
    /// este aviso en lugar de registrar.
    var weeklyRestNotice: String? = nil
    var onOpenDetail: (() -> Void)? = nil
    let onToggle: () -> Void

    @State private var showsWeeklyRestNotice = false

    private var restsOnWeeklyTarget: Bool {
        weeklyRestNotice != nil
    }

    /// Fila de un completado dentro de su grupo en Hoy: una sola línea. El fondo lo pone el grupo.
    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.xs) {
            Button(action: handleToggle) {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(restsOnWeeklyTarget ? habit.habitColor : .white)
                    .frame(width: 24, height: 24)
                    .background(toggleFill)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.xs, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.xs, style: .continuous)
                            .strokeBorder(toggleBorder, lineWidth: 1)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(toggleAccessibilityLabel)
            .accessibilityHint(weeklyRestNotice ?? "")
            .popover(isPresented: $showsWeeklyRestNotice) {
                Text(weeklyRestNotice ?? "")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(idealWidth: 240)
                    .padding(AppSpacing.m)
                    .presentationCompactAdaptation(.popover)
            }

            HStack(spacing: AppSpacing.s) {
                Text(habit.title)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(isStruckThrough ? AppColor.textSecondary : AppColor.textPrimary.opacity(0.72))
                    .strikethrough(isStruckThrough, color: AppColor.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: AppSpacing.s)

                HStack(spacing: AppSpacing.xs) {
                    if detail.isFocusSession {
                        Image(systemName: "timer")
                            .font(.system(size: 10, weight: .semibold))
                            .accessibilityLabel("Sesión de ritmo")
                    }

                    Text(detail.text)
                        .monospacedDigit()
                }
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .lineLimit(1)
                .fixedSize()
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
        .padding(.leading, AppSpacing.xs)
        .padding(.trailing, AppSpacing.l)
        .padding(.vertical, AppSpacing.xs)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
    }

    /// Solo se tacha lo que quedó hecho hoy por completo.
    private var isStruckThrough: Bool {
        !isMinimumCompleted && !restsOnWeeklyTarget
    }

    private func handleToggle() {
        guard restsOnWeeklyTarget else {
            onToggle()
            return
        }
        AppHaptics.play(.selection)
        showsWeeklyRestNotice = true
    }

    private var toggleFill: Color {
        if restsOnWeeklyTarget {
            return habit.habitColor.opacity(0.14)
        }
        return isMinimumCompleted ? habit.habitColor.opacity(0.55) : habit.habitColor
    }

    private var toggleBorder: Color {
        if restsOnWeeklyTarget {
            return habit.habitColor.opacity(0.5)
        }
        return isMinimumCompleted ? habit.habitColor : Color.clear
    }

    private var toggleAccessibilityLabel: String {
        if restsOnWeeklyTarget {
            return "\(habit.title): meta de la semana cumplida"
        }
        return isMinimumCompleted ? "Marcar completo \(habit.title)" : "Desmarcar \(habit.title)"
    }
}
