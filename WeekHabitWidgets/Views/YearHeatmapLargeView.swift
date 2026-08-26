//
//  YearHeatmapLargeView.swift
//  WeekHabitWidgets
//

import SwiftUI

/// `systemLarge` — la única familia del widget del año.
///
/// El año no entra en una sola tira legible a este ancho (52 columnas darían celdas de ~5 pt),
/// así que se parte en dos tiras de 26 semanas apiladas. Sin `ScrollView`: un widget no
/// desliza, la ventana es fija.
struct YearHeatmapLargeView: View {
    let snapshot: YearHeatmapSnapshot

    private let columnsPerStrip = 26
    private let cellSpacing: CGFloat = 3
    private let monthSpacing: CGFloat = 3
    private let monthLabelHeight: CGFloat = 12
    private let monthLabelSpacing: CGFloat = 6
    private let weekdayGutter: CGFloat = 14

    private var strips: [[YearHeatmapWeek]] {
        let weeks = snapshot.weeks
        guard weeks.count > columnsPerStrip else { return [weeks] }
        return [
            Array(weeks.prefix(weeks.count - columnsPerStrip)),
            Array(weeks.suffix(columnsPerStrip))
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            header

            GeometryReader { proxy in
                let cell = cellSize(in: proxy.size)
                VStack(alignment: .leading, spacing: AppSpacing.m) {
                    ForEach(Array(strips.enumerated()), id: \.offset) { _, strip in
                        YearHeatmapStrip(
                            weeks: strip,
                            cellSize: cell,
                            cellSpacing: cellSpacing,
                            monthSpacing: monthSpacing,
                            monthLabelHeight: monthLabelHeight,
                            monthLabelSpacing: monthLabelSpacing,
                            weekdayGutter: weekdayGutter
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            if snapshot.hasAnyHabit {
                legend
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(YearHeatmapCopy.accessibilityLabel(for: snapshot))
    }

    // MARK: - Encabezado

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(YearHeatmapCopy.eyebrow)
                .font(AppFont.micro)
                .foregroundStyle(AppColor.textTertiary)

            Text(YearHeatmapCopy.headline(for: snapshot))
                .font(AppFont.dataMetric)
                .foregroundStyle(AppColor.textPrimary)

            Text(YearHeatmapCopy.detail(for: snapshot))
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(2)
        }
    }

    // MARK: - Leyenda

    private var legend: some View {
        HStack(spacing: AppSpacing.xs) {
            Text(YearHeatmapCopy.legendLess)
                .font(AppFont.micro)
                .foregroundStyle(AppColor.textTertiary)

            ForEach(legendKinds, id: \.self) { kind in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(YearHeatmapAppearance.fill(for: kind))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .strokeBorder(YearHeatmapAppearance.border(for: kind), lineWidth: 1)
                    )
                    .frame(width: 10, height: 10)
            }

            Text(YearHeatmapCopy.legendMore)
                .font(AppFont.micro)
                .foregroundStyle(AppColor.textTertiary)
        }
    }

    private let legendKinds: [YearHeatmapDayKind] = [
        .nothingScheduled,
        .done(level: 1),
        .done(level: 2),
        .done(level: 3)
    ]

    // MARK: - Medidas

    /// Deriva el lado de la celda para que las dos tiras entren en el espacio real, acotado a
    /// un rango legible. Así funciona igual en un iPhone SE y en un iPad sin números mágicos.
    private func cellSize(in size: CGSize) -> CGFloat {
        let widthBudget = size.width - weekdayGutter - AppSpacing.s
            - CGFloat(columnsPerStrip - 1) * cellSpacing
            - CGFloat(maxMonthGaps) * monthSpacing
        let fromWidth = widthBudget / CGFloat(columnsPerStrip)

        // 2 tiras × (etiqueta de mes + su gap + 7 celdas + 6 gaps) + gap entre tiras.
        let stripChrome = monthLabelHeight + monthLabelSpacing + CGFloat(6) * cellSpacing
        let heightBudget = size.height - 2 * stripChrome - AppSpacing.m
        let fromHeight = heightBudget / CGFloat(14)

        return min(11, max(6, min(fromWidth, fromHeight)))
    }

    /// Cota superior de separaciones entre meses en una tira de 26 semanas: como mucho 7 meses
    /// distintos la tocan.
    private var maxMonthGaps: Int { 6 }
}

/// Una tira: columna de días L–D + columnas-semana agrupadas por mes.
private struct YearHeatmapStrip: View {
    let weeks: [YearHeatmapWeek]
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let monthSpacing: CGFloat
    let monthLabelHeight: CGFloat
    let monthLabelSpacing: CGFloat
    let weekdayGutter: CGFloat

    private var segments: [HeatmapMonthSegment] {
        HeatmapMonthSegment.segments(forWeekStarts: weeks.map(\.start))
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.s) {
            weekdayLabels

            HStack(alignment: .top, spacing: monthSpacing) {
                ForEach(segments) { segment in
                    VStack(alignment: .leading, spacing: monthLabelSpacing) {
                        Text(segment.label)
                            .font(AppFont.micro)
                            .foregroundStyle(AppColor.textTertiary)
                            .frame(height: monthLabelHeight, alignment: .bottomLeading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        HStack(alignment: .top, spacing: cellSpacing) {
                            ForEach(segment.weekIndices, id: \.self) { weekIndex in
                                if weeks.indices.contains(weekIndex) {
                                    column(for: weeks[weekIndex])
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func column(for week: YearHeatmapWeek) -> some View {
        VStack(spacing: cellSpacing) {
            ForEach(week.days, id: \.date) { day in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(YearHeatmapAppearance.fill(for: day.kind))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .strokeBorder(YearHeatmapAppearance.border(for: day.kind), lineWidth: 1)
                    )
                    .frame(width: cellSize, height: cellSize)
            }
        }
    }

    private var weekdayLabels: some View {
        VStack(spacing: monthLabelSpacing) {
            Color.clear
                .frame(width: weekdayGutter, height: monthLabelHeight)

            VStack(spacing: cellSpacing) {
                ForEach(Weekday.ordered) { weekday in
                    Text(weekday.oneLetterName)
                        .font(AppFont.micro)
                        .foregroundStyle(AppColor.textTertiary)
                        .frame(width: weekdayGutter, height: cellSize)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

#if DEBUG
import WidgetKit

#Preview("Large · año fuerte", as: .systemLarge) {
    YearHeatmapWidget()
} timeline: {
    YearHeatmapEntry(date: .now, content: .snapshot(.sampleStrongYear))
}

#Preview("Large · año a medias", as: .systemLarge) {
    YearHeatmapWidget()
} timeline: {
    YearHeatmapEntry(date: .now, content: .snapshot(.sampleMixedYear))
}

#Preview("Large · primeros días", as: .systemLarge) {
    YearHeatmapWidget()
} timeline: {
    YearHeatmapEntry(date: .now, content: .snapshot(.sampleEarlyDays))
}

#Preview("Large · sin hábitos", as: .systemLarge) {
    YearHeatmapWidget()
} timeline: {
    YearHeatmapEntry(date: .now, content: .snapshot(.sampleEmpty))
}

#Preview("Large · no disponible", as: .systemLarge) {
    YearHeatmapWidget()
} timeline: {
    YearHeatmapEntry(date: .now, content: .unavailable)
}
#endif
