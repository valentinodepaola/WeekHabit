//
//  SplashBrandLockup.swift
//  WeekHabit
//

import SwiftUI

struct SplashBrandLockup: View {
    var body: some View {
        VStack(spacing: 9) {
            Text("WeekHabit")
                .font(AppFont.title1)
                .foregroundStyle(AppColor.strongText)

            Text("Una semana. Un ritmo.")
                .font(AppFont.body2)
                .foregroundStyle(AppColor.mutedText)
        }
    }
}

