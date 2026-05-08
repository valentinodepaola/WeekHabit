//
//  ExperimentReviewCard.swift
//  WeekHabit
//
//  Cierre de experimento con narrativa, no botones desnudos.
//

import SwiftUI

struct ExperimentReviewCard: View {
    let experiment: HabitExperiment
    let habit: Habit
    let referenceDate: Date
    let onKeep: () -> Void
    let onRevert: () -> Void

    private var currentConsistency: Double {
        experiment.currentConsistency(for: habit, reference: referenceDate)
    }

    private var delta: Int {
        Int(((currentConsistency - experiment.baselineConsistency) * 100).rounded())
    }

    private var deltaColor: Color {
        if delta > 0 { return AppColor.success }
        if delta < 0 { return AppColor.warning }
        return AppColor.textSecondary
    }

    private var resultHeadline: String {
        if delta > 0 { return "Mejoró \(delta) puntos" }
        if delta < 0 { return "Bajó \(abs(delta)) puntos" }
        return "Se mantuvo estable"
    }

    private var resultNarrative: String {
        if delta > 0 {
            return "Tu consistencia subió frente al ritmo anterior. Hay evidencia de que este cambio te sirve."
        }
        if delta < 0 {
            return "Tu consistencia bajó. No es un fracaso — es información para ajustar."
        }
        return "El ritmo se sostuvo similar al anterior. Puedes mantenerlo si te resulta más cómodo."
    }

    private var keepLabel: String {
        delta >= 0 ? "Conservar este ritmo" : "Conservar de todas formas"
    }

    private var revertLabel: String {
        delta < 0 ? "Volver al ritmo anterior" : "Volver al anterior"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            // Caption
            HStack(spacing: AppSpacing.s) {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.info)
                Text("LISTO PARA REVISAR")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.8)
            }

            // Habit + headline
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(habit.title)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textPrimary)

                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.s) {
                    Text(resultHeadline)
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(deltaColor)

                    deltaPill
                }
            }

            // Narrative
            Text(resultNarrative)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Compact metrics
            HStack(spacing: AppSpacing.l) {
                metricColumn(
                    label: "Antes",
                    value: "\(Int((experiment.baselineConsistency * 100).rounded()))%"
                )
                Rectangle()
                    .fill(AppColor.divider)
                    .frame(width: 1, height: 32)
                metricColumn(
                    label: "Durante",
                    value: "\(Int((currentConsistency * 100).rounded()))%"
                )
            }
            .padding(AppSpacing.m)
            .frame(maxWidth: .infinity)
            .background(AppColor.bgSunken.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))

            // Decisión
            VStack(spacing: AppSpacing.s) {
                WHButton(title: keepLabel, icon: "checkmark", variant: .primary, action: onKeep)
                WHButton(title: revertLabel, icon: "arrow.uturn.backward", variant: .secondary, action: onRevert)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.l)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(.low)
    }

    private var deltaPill: some View {
        Text(delta == 0 ? "0%" : (delta > 0 ? "+\(delta)%" : "\(delta)%"))
            .font(AppFont.label)
            .monospacedDigit()
            .foregroundStyle(deltaColor)
            .padding(.horizontal, AppSpacing.s)
            .padding(.vertical, AppSpacing.xs)
            .background(deltaColor.opacity(0.14))
            .clipShape(Capsule())
    }

    private func metricColumn(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(label.uppercased())
                .font(AppFont.label)
                .tracking(0.8)
                .foregroundStyle(AppColor.textTertiary)
            Text(value)
                .font(.system(size: 22, weight: .regular, design: .serif))
                .monospacedDigit()
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
