//
//  InsightsHeroCard.swift
//  WeekHabit
//

import SwiftUI

struct InsightsHeroCard: View {
    let snapshot: GlobalInsightSnapshot
    var readiness: InsightReadiness? = nil

    private var consistencyText: String {
        snapshot.current.scheduled == 0 ? "—" : "\(snapshot.current.percentage)%"
    }

    private var deltaText: String {
        let delta = snapshot.deltaPercentagePoints
        if delta == 0 { return "0%" }
        return delta > 0 ? "+\(delta)%" : "\(delta)%"
    }

    private var deltaColor: Color {
        snapshot.deltaPercentagePoints >= 0 ? AppColor.success : AppColor.warning
    }

    private var message: String {
        if let readiness, !readiness.isReady {
            return "La gráfica ya reacciona a tus marcas, pero todavía estoy juntando contexto."
        }
        if let readiness, readiness.isProvisional {
            return "La señal ya es útil, pero todavía puede moverse con pocos datos."
        }
        guard snapshot.current.scheduled > 0 else {
            return "Marca algunos hábitos para empezar a leer tu ritmo."
        }
        if snapshot.previous.scheduled == 0 {
            return "Ya tengo una base para empezar a comparar tu ritmo."
        }
        if snapshot.deltaPercentagePoints > 0 {
            return "Has mejorado frente a los 30 días anteriores."
        }
        if snapshot.deltaPercentagePoints < 0 {
            return "Tu ritmo cambió frente al periodo anterior."
        }
        return "Te mantuviste estable frente al periodo anterior."
    }

    private var encouragement: String {
        if let readiness, !readiness.isReady {
            return readiness.remainingDays == 1
                ? "Falta 1 día para activar Insights."
                : "Faltan \(readiness.remainingDays) días para activar Insights."
        }
        if snapshot.current.scheduled == 0 { return "Empieza suave." }
        return snapshot.deltaPercentagePoints >= 0
            ? "Sigue así."
            : "Volvamos con un paso pequeño."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            HStack(spacing: AppSpacing.s) {
                Text("CONSISTENCIA GLOBAL")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(1.2)
                    .lineLimit(1)

                if readiness?.isProvisional == true {
                    InsightProvisionalBadge()
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.s) {
                Text(consistencyText)
                    .font(.system(size: 64, weight: .regular, design: .serif))
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .monospacedDigit()

                if snapshot.previous.scheduled > 0 {
                    Text(deltaText)
                        .font(AppFont.label)
                        .foregroundStyle(deltaColor)
                        .padding(.horizontal, AppSpacing.s)
                        .padding(.vertical, AppSpacing.xs)
                        .background(deltaColor.opacity(0.14))
                        .clipShape(Capsule())
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(message)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)

                Text(encouragement)
                    .font(AppFont.callout.italic())
                    .foregroundStyle(AppColor.accent)
            }
            .fixedSize(horizontal: false, vertical: true)

            InsightsTrendBars(values: snapshot.trend)
                .padding(.top, AppSpacing.xs)

            Text("Cada barra resume una parte de los últimos 30 días; más alta significa más cumplimiento.")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.xl)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .appElevation(.low)
    }
}

#Preview {
    InsightsHeroCard(
        snapshot: GlobalInsightSnapshot(
            current: HabitCompletionStats(completed: 12, scheduled: 17),
            previous: HabitCompletionStats(completed: 10, scheduled: 17),
            trend: [0.2, 0.3, 0.15, 0.35, 0.28, 0.5, 0.62, 0.4, 0.55, 0.82, 0.75, 0.88]
        )
    )
    .padding()
    .background(AppColor.bgCanvas)
}
