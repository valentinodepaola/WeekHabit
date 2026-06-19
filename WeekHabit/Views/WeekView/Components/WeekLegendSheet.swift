//
//  WeekLegendSheet.swift
//  WeekHabit
//

import SwiftUI

struct WeekLegendSheet: View {
    private let sampleColor = AppColor.accent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                header

                VStack(alignment: .leading, spacing: AppSpacing.l) {
                    ForEach(WeekGridCellFamily.allCases) { family in
                        familySection(family)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.l)
            .padding(.top, AppSpacing.l)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColor.bgCanvas)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Leyenda")
                .font(AppFont.headline)
                .foregroundStyle(AppColor.textPrimary)

            Text("Cada celda resume qué pasó con un hábito en un día.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private func familySection(_ family: WeekGridCellFamily) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(family.title.uppercased())
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.8)

                Text(family.description)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: AppSpacing.s) {
                ForEach(family.states, id: \.self) { state in
                    legendRow(for: state)
                }
            }
        }
    }

    private func legendRow(for state: WeekGridCell.State) -> some View {
        HStack(alignment: .center, spacing: AppSpacing.m) {
            WeekGridCell(
                state: state,
                habitColor: sampleColor,
                isInteractive: false,
                onTap: {},
                onSkip: {}
            )
            .frame(width: WeekGridLayout.cellSize, height: WeekGridLayout.cellSize)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(state.legendTitle)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.textPrimary)

                Text(state.legendDescription)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.m)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(AppColor.divider.opacity(0.75), lineWidth: 1)
        }
    }
}

#Preview {
    WeekLegendSheet()
        .preferredColorScheme(.dark)
}
