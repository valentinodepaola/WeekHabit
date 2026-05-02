//
//  SplashCoreIcon.swift
//  WeekHabit
//

import SwiftUI

struct SplashCoreIcon: View {
    let isExpanded: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColor.surface)
                .frame(width: 92, height: 92)
                .shadow(color: AppColor.strongText.opacity(0.08), radius: 18, x: 0, y: 12)

            Circle()
                .fill(AppColor.accent.opacity(0.14))
                .frame(width: 76, height: 76)

            Circle()
                .fill(AppColor.accent)
                .frame(width: 61, height: 61)

            Image(systemName: "flame.fill")
                .font(.system(size: 27, weight: .semibold))
                .foregroundStyle(.white)
                .scaleEffect(isExpanded ? 1.08 : 0.96)
        }
    }
}

