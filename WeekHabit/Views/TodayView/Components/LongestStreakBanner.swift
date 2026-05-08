//
//  LongestStreakBanner.swift
//  WeekHabit
//

import SwiftUI

struct LongestStreakBanner: View {
    let habitTitle: String
    let streakDays: Int
    var allSameStreak: Bool = false

    private var caption: String {
        allSameStreak ? "TODOS VOLVIENDO" : "IMPULSO ACTUAL"
    }

    private var titleText: String {
        let dayWord = streakDays == 1 ? "día" : "días"
        if allSameStreak {
            return "Todos tus hábitos · \(streakDays) \(dayWord) volviendo"
        }
        return "\(habitTitle) · \(streakDays) \(dayWord) volviendo"
    }

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.18))
                Image(systemName: "flame.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(caption)
                    .font(AppFont.label)
                    .foregroundStyle(.white.opacity(0.85))
                    .tracking(0.8)
                Text(titleText)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.vertical, AppSpacing.m)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.l)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColor.accent,
                            AppColor.warning
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .appElevation(.low)
    }
}

#Preview {
    VStack(spacing: AppSpacing.m) {
        LongestStreakBanner(habitTitle: "Meditar", streakDays: 9)
        LongestStreakBanner(habitTitle: "—", streakDays: 3, allSameStreak: true)
    }
    .padding()
    .background(AppColor.bgCanvas)
}
