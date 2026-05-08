//
//  CurrentStreakHeroCard.swift
//  WeekHabit
//

import SwiftUI

struct CurrentStreakHeroCard: View {
    let habit: Habit
    let currentStreak: Int
    let bestStreak: Int

    private var isActive: Bool { currentStreak > 0 }

    private var gradient: LinearGradient {
        if isActive {
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
                Text("CONSTANCIA ACTUAL")
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

                Text(flavorText)
                    .font(AppFont.callout)
                    .foregroundStyle(foregroundColor)
                    .opacity(isActive ? 1 : 0.7)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.l)
        }
        .frame(maxWidth: .infinity, minHeight: 178)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(isActive ? .medium : .low)
    }

    private var flavorText: String {
        if currentStreak == 0 {
            return "Hoy también cuenta. Vuelve con una marca pequeña."
        }
        if currentStreak == bestStreak {
            return "Estás construyendo una referencia nueva, día a día."
        }
        return "Cada día que vuelves cuenta. Tu referencia: \(bestStreak) \(bestStreak == 1 ? "día" : "días")."
    }
}

#Preview {
    VStack(spacing: AppSpacing.m) {
        CurrentStreakHeroCard(
            habit: Habit(
                title: "Tomar agua",
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
                title: "Tomar agua",
                iconName: "drop.fill",
                colorHex: "#7fa774",
                targetDaysPerWeek: 5,
                activeDaysOfWeek: Set(Weekday.ordered)
            ),
            currentStreak: 0,
            bestStreak: 7
        )
    }
    .padding()
    .background(AppColor.bgCanvas)
}
