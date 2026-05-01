//
//  SplashWeekStrip.swift
//  WeekHabit
//

import SwiftUI

struct SplashWeekStrip: View {
    let progress: CGFloat

    var body: some View {
        HStack(spacing: 7) {
            ForEach(Weekday.ordered.indices, id: \.self) { index in
                let isActive = progress >= CGFloat(index + 1) / CGFloat(Weekday.ordered.count) - 0.02

                Capsule()
                    .fill(isActive ? AppColor.accent : AppColor.subtleText.opacity(0.18))
                    .frame(width: isActive ? 26 : 10, height: 6)
                    .animation(SplashScreenMotion.weekStrip(index: index), value: isActive)
            }
        }
        .frame(height: 10)
    }
}

