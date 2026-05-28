//
//  LongestStreakBanner.swift
//  WeekHabit
//

import SwiftUI

struct LongestStreakBanner: View {
    let habit: Habit?
    let streakDays: Int
    var allSameStreak: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var caption: String {
        IdentityReinforcementCopy.longestBannerCaption(
            for: habit,
            allSameStreak: allSameStreak
        )
    }

    private var titleText: String {
        IdentityReinforcementCopy.longestBannerTitle(
            for: habit,
            streakDays: streakDays,
            allSameStreak: allSameStreak
        )
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
                Text(caption.uppercased(with: Locale(identifier: "es_MX")))
                    .font(AppFont.label)
                    .foregroundStyle(.white)
                    .tracking(0.8)
                Text(titleText)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .animation(AppMotion.respectful(AppMotion.smooth, reduceMotion), value: titleText)
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
        LongestStreakBanner(
            habit: Habit(
                title: "Meditar",
                iconName: "sparkles",
                colorHex: "#c78f5a",
                targetDaysPerWeek: 7,
                activeDaysOfWeek: Set(Weekday.ordered)
            ),
            streakDays: 9
        )
        LongestStreakBanner(
            habit: Habit(
                title: "Comprar cosas por impulso",
                iconName: "cart.fill",
                colorHex: "#7fa774",
                targetDaysPerWeek: 7,
                activeDaysOfWeek: Set(Weekday.ordered),
                direction: .break
            ),
            streakDays: 12
        )
        LongestStreakBanner(habit: nil, streakDays: 3, allSameStreak: true)
    }
    .padding()
    .background(AppColor.bgCanvas)
}
