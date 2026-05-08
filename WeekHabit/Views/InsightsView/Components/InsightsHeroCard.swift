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
        snapshot.deltaPercentagePoints >= 0 ? Color(hex: "#6f9a64") : AppColor.accent
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
            return readiness.remainingDays == 1 ? "Falta 1 día para activar Insights." : "Faltan \(readiness.remainingDays) días para activar Insights."
        }

        if snapshot.current.scheduled == 0 { return "Empieza suave." }
        return snapshot.deltaPercentagePoints >= 0 ? "Sigue así." : "Volvamos con un paso pequeño."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                Text("CONSISTENCIA GLOBAL")
                    .font(AppFont.formSectionText)
                    .foregroundStyle(AppColor.mutedText)
                    .tracking(1.6)
                    .lineLimit(1)

                if readiness?.isProvisional == true {
                    InsightProvisionalBadge()
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(consistencyText)
                    .font(.system(size: 56, weight: .semibold, design: .default))
                    .foregroundStyle(AppColor.strongText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if snapshot.previous.scheduled > 0 {
                    Text(deltaText)
                        .font(AppFont.body2)
                        .fontWeight(.bold)
                        .foregroundStyle(deltaColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(deltaColor.opacity(0.14))
                        .clipShape(Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(message)
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.mutedText)

                Text(encouragement)
                    .font(AppFont.body2)
                    .italic()
                    .foregroundStyle(AppColor.accent)
            }
            .fixedSize(horizontal: false, vertical: true)

            InsightsTrendBars(values: snapshot.trend)
                .padding(.top, 6)

            Text("Cada barra resume una parte de los últimos 30 días; más alta significa más cumplimiento.")
                .font(AppFont.captionApp)
                .foregroundStyle(AppColor.subtleText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: "#e8dcc8"), lineWidth: 1)
        }
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
    .background(AppColor.bgLight)
}
