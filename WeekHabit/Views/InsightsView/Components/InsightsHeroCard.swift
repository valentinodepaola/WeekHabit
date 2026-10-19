//
//  InsightsHeroCard.swift
//  WeekHabit
//

import SwiftUI

struct InsightsHeroCard: View {
    let snapshot: GlobalInsightSnapshot
    var readiness: InsightReadiness? = nil
    var title: String = "CONSISTENCIA GLOBAL"
    /// Cuando llega, la tarjeta muestra el selector Semana / Mes / Todo y el rango de fechas.
    var periodSelection: Binding<InsightPeriod>? = nil

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

    /// El primer día de la semana: un solo día todavía no dice nada del ritmo semanal.
    private var isWeekJustStarting: Bool {
        snapshot.period == .week && snapshot.trend.filter { !$0.isPending }.count <= 1
    }

    /// Semanas de historial cuando todavía no alcanzan para comparar el primer mes.
    private var shortHistoryWeeks: Int? {
        guard snapshot.period == .all, snapshot.granularity == .week, snapshot.trend.count < 9 else { return nil }
        return snapshot.trend.count
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
        guard snapshot.comparison != nil else {
            if isWeekJustStarting {
                return "La semana apenas empieza."
            }
            if let weeks = shortHistoryWeeks {
                let span = weeks == 1 ? "1 semana" : "\(weeks) semanas"
                return "Llevas \(span). Al cumplir dos meses te muestro cuánto cambiaste."
            }
            return "Ya tengo una base para empezar a comparar tu ritmo."
        }

        let delta = snapshot.deltaPercentagePoints
        switch snapshot.period {
        case .week:
            if delta > 0 { return "Vas mejor que la semana pasada." }
            if delta < 0 { return "Tu ritmo cambió frente a la semana pasada." }
            return "Te mantuviste igual que la semana pasada."
        case .month:
            if delta > 0 { return "Has mejorado frente a los 30 días anteriores." }
            if delta < 0 { return "Tu ritmo cambió frente al periodo anterior." }
            return "Te mantuviste estable frente al periodo anterior."
        case .all:
            if delta > 0 { return "Has mejorado desde tu primer mes." }
            if delta < 0 { return "Tu ritmo cambió desde tu primer mes." }
            return "Te mantuviste estable desde tu primer mes."
        }
    }

    private var encouragement: String {
        if let readiness, !readiness.isReady {
            return readiness.remainingDays == 1
                ? "Falta 1 día para activar Insights."
                : "Faltan \(readiness.remainingDays) días para activar Insights."
        }
        if snapshot.current.scheduled == 0 { return "Empieza suave." }
        if snapshot.comparison == nil && isWeekJustStarting { return "Lo que marques hoy ya cuenta." }
        return snapshot.deltaPercentagePoints >= 0
            ? "Sigue así."
            : "Volvamos con un paso pequeño."
    }

    private var trendCaption: String {
        switch snapshot.granularity {
        case .day:
            let base = "Cada barra es un día de esta semana; más alta significa más cumplimiento."
            return snapshot.trend.contains(where: \.isPending)
                ? base + " Los días que faltan quedan punteados."
                : base
        case .monthSlice:
            return "Cada barra resume una parte de los últimos 30 días; más alta significa más cumplimiento."
        case .week:
            return "Cada barra es una semana desde que empezaste; más alta significa más cumplimiento."
        case .month:
            return "Cada barra es un mes desde que empezaste; más alta significa más cumplimiento."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            HStack(spacing: AppSpacing.s) {
                Text(title)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .lineLimit(1)

                if readiness?.isProvisional == true {
                    InsightProvisionalBadge()
                }

                if periodSelection != nil {
                    Spacer(minLength: AppSpacing.s)

                    Text(snapshot.rangeText)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)
                        .lineLimit(1)
                        .monospacedDigit()
                }
            }

            if let periodSelection {
                Picker("Periodo", selection: periodSelection) {
                    ForEach(InsightPeriod.allCases) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.s) {
                Text(consistencyText)
                    .font(AppFont.insightHeroMetric)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                if snapshot.comparison != nil {
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

            InsightsTrendBars(bars: snapshot.trend)
                .padding(.top, AppSpacing.xs)

            if snapshot.minimumDays > 0 {
                minimumVersionNote
            }

            Text(trendCaption)
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .insightCard(padding: AppSpacing.xl, cornerRadius: AppRadius.xl)
    }

    private var minimumVersionNote: some View {
        HStack(alignment: .top, spacing: AppSpacing.s) {
            Image(systemName: "checkmark.circle")
                .font(AppFont.label)
                .foregroundStyle(AppColor.info)
                .frame(width: 22, height: 22)
                .background(AppColor.info.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(minimumDaysText)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)

                Text("Cuentan para tu racha pero no para la tasa")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, AppSpacing.m)
        .padding(.vertical, AppSpacing.s)
        .background(AppColor.info.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .strokeBorder(AppColor.info.opacity(0.20), lineWidth: 1)
        }
    }

    private var minimumDaysText: String {
        snapshot.minimumDays == 1
            ? "1 día con versión mínima"
            : "\(snapshot.minimumDays) días con versión mínima"
    }
}

#Preview {
    @Previewable @State var period: InsightPeriod = .month

    InsightsHeroCard(
        snapshot: GlobalInsightSnapshot(
            period: .month,
            current: HabitCompletionStats(completed: 12, scheduled: 17),
            comparison: InsightComparison(
                baseline: HabitCompletionStats(completed: 10, scheduled: 17),
                recent: HabitCompletionStats(completed: 12, scheduled: 17)
            ),
            trend: [0.2, 0.3, 0.15, 0.35, 0.28, 0.5, 0.62, 0.4, 0.55, 0.82, 0.75, 0.88]
                .map { InsightTrendBar(value: $0) },
            granularity: .monthSlice,
            range: Date.now.addingTimeInterval(-29 * 86_400)...Date.now,
            minimumDays: 3
        ),
        periodSelection: $period
    )
    .padding()
    .background(AppColor.bgCanvas)
}
