//
//  InsightSummaryCard.swift
//  WeekHabit
//

import SwiftUI

struct InsightSummaryCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let detail: String
    var isProvisional: Bool = false
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .fill(iconColor.opacity(0.14))
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack(spacing: AppSpacing.s) {
                    Text(title)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)
                        .tracking(0.8)
                        .lineLimit(1)

                    if isProvisional {
                        InsightProvisionalBadge()
                    }
                }

                Text(value)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(detail)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppSpacing.s)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.accent)
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.vertical, AppSpacing.m)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(.low)
    }
}

#Preview {
    VStack(spacing: AppSpacing.s) {
        InsightSummaryCard(
            icon: "calendar",
            iconColor: AppColor.info,
            title: "TU MEJOR DÍA",
            value: "Lunes",
            detail: "84% de cumplimiento promedio"
        )
        InsightSummaryCard(
            icon: "clock",
            iconColor: AppColor.warning,
            title: "TU HORA PUNTA",
            value: "8:00 — 11:00",
            detail: "Mayor consistencia en la mañana",
            isProvisional: true,
            actionTitle: "Editar",
            action: {}
        )
    }
    .padding()
    .background(AppColor.bgCanvas)
}
