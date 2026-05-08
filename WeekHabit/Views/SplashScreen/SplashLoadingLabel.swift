//
//  SplashLoadingLabel.swift
//  WeekHabit
//

import SwiftUI

struct SplashLoadingLabel: View {
    var body: some View {
        Text("Preparando tu ritmo")
            .font(AppFont.label)
            .foregroundStyle(AppColor.textTertiary)
            .padding(.bottom, AppSpacing.l)
    }
}
