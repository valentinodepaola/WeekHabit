//
//  InsightProvisionalBadge.swift
//  WeekHabit
//

import SwiftUI

struct InsightProvisionalBadge: View {
    var text: String = "Provisional"

    var body: some View {
        Text(text)
            .font(AppFont.formSectionText2)
            .foregroundStyle(AppColor.accent)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AppColor.accentSoft)
            .clipShape(Capsule())
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel("Insight provisional")
    }
}

#Preview {
    InsightProvisionalBadge()
        .padding()
        .background(AppColor.bgLight)
}
