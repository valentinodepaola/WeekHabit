//
//  OnboardingProgressView.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingProgressView: View {
    let currentIndex: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= currentIndex ? AppColor.accent : AppColor.subtleText.opacity(0.22))
                    .frame(height: 3)
            }
        }
        .frame(height: 8)
    }
}
