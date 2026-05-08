//
//  InsightProvisionalBadge.swift
//  WeekHabit
//

import SwiftUI

struct InsightProvisionalBadge: View {
    var text: String = "Provisional"

    var body: some View {
        Text(text)
            .font(AppFont.label)
            .foregroundStyle(AppColor.warning)
            .lineLimit(1)
            .padding(.horizontal, AppSpacing.s)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColor.warning.opacity(0.14))
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(AppColor.warning.opacity(0.25), lineWidth: 1)
            )
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel("Insight provisional")
    }
}

#Preview {
    InsightProvisionalBadge()
        .padding()
        .background(AppColor.bgCanvas)
}
