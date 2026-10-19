//
//  InsightsTrendBars.swift
//  WeekHabit
//

import SwiftUI

struct InsightsTrendBars: View {
    let bars: [InsightTrendBar]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let minimumBarHeight: CGFloat = 16
    private let barRange: CGFloat = 52

    /// Con pocas barras (un historial de 2 semanas) no se estiran a lo ancho: quedan
    /// angostas y a la izquierda, para que no se lean como bloques.
    private var isSparse: Bool { bars.count <= 4 }

    private var recentIndices: Set<Int> {
        Set(bars.indices.filter { !bars[$0].isPending }.suffix(3))
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: bars.count > 12 ? AppSpacing.xs : AppSpacing.s) {
            ForEach(Array(bars.enumerated()), id: \.offset) { index, bar in
                VStack(spacing: AppSpacing.s) {
                    barShape(bar, index: index)
                        .frame(height: barHeight(for: bar))
                        .frame(height: minimumBarHeight + barRange, alignment: .bottom)

                    label(for: bar)
                }
                .frame(maxWidth: isSparse ? 44 : .infinity)
            }

            if isSparse {
                Spacer(minLength: 0)
            }
        }
        .animation(AppMotion.respectful(AppMotion.smooth, reduceMotion), value: bars)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func barShape(_ bar: InsightTrendBar, index: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: AppRadius.xs, style: .continuous)

        if bar.isPending {
            // Un día que todavía no llega: en espera, nunca como un día fallido.
            shape.strokeBorder(AppColor.divider, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        } else {
            shape.fill(color(for: bar, index: index))
        }
    }

    /// La etiqueta puede ser más ancha que su barra ("hace 30 días"): se dibuja encima de
    /// un hueco de alto fijo y desborda hacia el lado que indica su alineación.
    private func label(for bar: InsightTrendBar) -> some View {
        Color.clear
            .frame(height: 14)
            .overlay(alignment: overlayAlignment(for: bar.labelAlignment)) {
                if let label = bar.label {
                    Text(label)
                        .font(AppFont.micro)
                        .fontWeight(bar.isCurrent ? .bold : .medium)
                        .foregroundStyle(bar.isCurrent ? AppColor.textPrimary : AppColor.textTertiary)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
    }

    private func overlayAlignment(for alignment: InsightTrendBar.LabelAlignment) -> Alignment {
        switch alignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    private func barHeight(for bar: InsightTrendBar) -> CGFloat {
        minimumBarHeight + CGFloat(max(0, min(bar.value ?? 0, 1))) * barRange
    }

    private func color(for bar: InsightTrendBar, index: Int) -> Color {
        guard let value = bar.value, value > 0 else { return AppColor.divider.opacity(0.6) }
        return recentIndices.contains(index) ? AppColor.accent : AppColor.accent.opacity(0.35)
    }
}

#Preview {
    VStack(spacing: AppSpacing.xl) {
        InsightsTrendBars(bars: [0.62, 0.8, 0.45, 0.7, nil, nil, nil].enumerated().map { index, value in
            InsightTrendBar(
                value: value,
                label: Weekday.ordered[index].oneLetterName,
                isCurrent: index == 3
            )
        })

        InsightsTrendBars(bars: [
            InsightTrendBar(value: 0.55, label: "5 oct"),
            InsightTrendBar(value: 0.68, label: "12 oct", isCurrent: true)
        ])
    }
    .padding()
    .background(AppColor.bgElevated)
}
