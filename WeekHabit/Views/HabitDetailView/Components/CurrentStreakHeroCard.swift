//
//  CurrentStreakHeroCard.swift
//  WeekHabit
//

import SwiftUI

struct CurrentStreakHeroCard: View {
    let habit: Habit
    let currentStreak: Int
    let bestStreak: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isActive: Bool { currentStreak > 0 }

    private var caption: String {
        IdentityReinforcementCopy.streakHeroCaption(for: habit, currentStreak: currentStreak)
    }

    private var identityFlavor: String {
        IdentityReinforcementCopy.streakHeroFlavor(
            for: habit,
            currentStreak: currentStreak,
            bestStreak: bestStreak
        )
    }

    private var gradient: LinearGradient {
        if isActive {
            if habit.isBreakHabit {
                return LinearGradient(
                    colors: [AppColor.info, AppColor.success],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            return LinearGradient(
                colors: [AppColor.accent, AppColor.warning],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [AppColor.bgElevated, AppColor.bgSunken],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var foregroundColor: Color {
        isActive ? .white : AppColor.textPrimary
    }

    private var captionColor: Color {
        isActive ? .white.opacity(0.85) : AppColor.textTertiary
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .fill(gradient)

            Image(systemName: "flame.fill")
                .font(.system(size: 110, weight: .bold))
                .foregroundStyle(foregroundColor.opacity(isActive ? 0.18 : 0.08))
                .offset(x: 22, y: 10)

            VStack(alignment: .leading, spacing: AppSpacing.m) {
                Text(caption.uppercased(with: Locale(identifier: "es")))
                    .font(AppFont.label)
                    .tracking(0.8)
                    .foregroundStyle(captionColor)

                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.s) {
                    Text("\(currentStreak)")
                        .font(.system(size: 56, weight: .regular, design: .serif))
                        .monospacedDigit()
                        .foregroundStyle(foregroundColor)

                    Text(currentStreak == 1 ? "día" : "días")
                        .font(AppFont.headline)
                        .foregroundStyle(foregroundColor)
                }

                Text(identityFlavor)
                    .font(AppFont.callout)
                    .foregroundStyle(foregroundColor)
                    .opacity(isActive ? 1 : 0.7)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(AppMotion.respectful(AppMotion.smooth, reduceMotion), value: identityFlavor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.l)
        }
        .frame(maxWidth: .infinity, minHeight: 178)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(isActive ? .medium : .low)
    }
}

#Preview {
    VStack(spacing: AppSpacing.m) {
        CurrentStreakHeroCard(
            habit: Habit(
                title: "Leer antes de dormir",
                iconName: "drop.fill",
                colorHex: "#7fa774",
                targetDaysPerWeek: 5,
                activeDaysOfWeek: Set(Weekday.ordered)
            ),
            currentStreak: 5,
            bestStreak: 7
        )

        CurrentStreakHeroCard(
            habit: Habit(
                title: "Comprar cosas por impulso",
                iconName: "drop.fill",
                colorHex: "#7fa774",
                targetDaysPerWeek: 5,
                activeDaysOfWeek: Set(Weekday.ordered),
                direction: .break
            ),
            currentStreak: 0,
            bestStreak: 7
        )
    }
    .padding()
    .background(AppColor.bgCanvas)
}
