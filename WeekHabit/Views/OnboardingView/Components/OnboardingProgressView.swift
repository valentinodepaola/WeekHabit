//
//  OnboardingProgressView.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingProgressView: View {
    let currentIndex: Int
    let total: Int

    var body: some View {
        HStack(spacing: AppSpacing.s) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= currentIndex ? AppColor.accent : AppColor.divider)
                    .frame(height: 3)
            }
        }
        .frame(height: 8)
    }
}
