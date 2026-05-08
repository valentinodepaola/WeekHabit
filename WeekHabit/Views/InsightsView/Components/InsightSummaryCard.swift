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
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(AppFont.formSectionText)
                        .foregroundStyle(AppColor.mutedText)
                        .tracking(1.2)
                        .lineLimit(1)

                    if isProvisional {
                        InsightProvisionalBadge()
                    }
                }

                Text(value)
                    .font(AppFont.subtitle3)
                    .foregroundStyle(AppColor.strongText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(detail)
                    .font(AppFont.captionApp)
                    .foregroundStyle(AppColor.subtleText)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(AppFont.formSectionText)
                    .foregroundStyle(AppColor.accent)
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Color(hex: "#e8dcc8"), lineWidth: 1)
        }
    }
}

#Preview {
    InsightSummaryCard(
        icon: "calendar",
        iconColor: AppColor.editAction,
        title: "TU MEJOR DÍA",
        value: "Lunes",
        detail: "84% de cumplimiento promedio"
    )
    .padding()
    .background(AppColor.bgLight)
}
