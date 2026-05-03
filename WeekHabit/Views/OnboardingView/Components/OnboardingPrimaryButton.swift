//
//  OnboardingPrimaryButton.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppColor.accent)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
