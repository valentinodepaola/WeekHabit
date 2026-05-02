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
            return "Tu ritmo bajó un poco frente al periodo anterior."
        }

        return "Te mantuviste estable frente al periodo anterior."
    }

    private var encouragement: String {
        if let readiness, !readiness.isReady {
            return readiness.remainingDays == 1 ? "Falta 1 día para activar Insights." : "Faltan \(readiness.remainingDays) días para activar Insights."
        }

        if snapshot.current.scheduled == 0 { return "Empieza suave." }
        return snapshot.deltaPercentagePoints >= 0 ? "Sigue así." : "Ajustemos el plan."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("CONSISTENCIA GLOBAL")
                .font(AppFont.formSectionText)
                .foregroundStyle(AppColor.mutedText)
                .tracking(1.6)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(consistencyText)
                    .font(.system(size: 64, weight: .regular, design: .serif))
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
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
