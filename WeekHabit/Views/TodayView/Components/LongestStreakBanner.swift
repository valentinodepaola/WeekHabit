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

    private var titleText: String {
        IdentityReinforcementCopy.longestBannerTitle(
            for: habit,
            streakDays: streakDays,
            allSameStreak: allSameStreak
        )
    }

    var body: some View {
        // Una línea: el título ya dice qué tramo es ("· 4 días eligiendo distinto").
        HStack(spacing: AppSpacing.m) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.22))
                Image(systemName: "flame.fill")
                    .font(AppFont.iconSmall)
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)

            Text(titleText)
                .font(AppFont.callout.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .animation(AppMotion.respectful(AppMotion.smooth, reduceMotion), value: titleText)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.m)
        .padding(.vertical, AppSpacing.s)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.m)
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
