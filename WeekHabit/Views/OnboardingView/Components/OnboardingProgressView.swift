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

#Preview {
    VStack(spacing: AppSpacing.l) {
        OnboardingProgressView(currentIndex: 0, total: 3)
        OnboardingProgressView(currentIndex: 1, total: 3)
        OnboardingProgressView(currentIndex: 2, total: 3)
    }
    .padding()
    .background(AppColor.bgCanvas)
}
