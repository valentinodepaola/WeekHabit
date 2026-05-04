//
//  CurrentStreakHeroCard.swift
//  WeekHabit
//

import SwiftUI

struct CurrentStreakHeroCard: View {
    let habit: Habit
    let currentStreak: Int
    let bestStreak: Int

    var body: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .fill(currentStreak == 0 ? .gray : .orange)

            Image(systemName: "flame.fill")
                .font(.system(size: 118, weight: .bold))
                .foregroundStyle(.white.opacity(0.15))
                .offset(x: 22, y: 10)

            VStack(alignment: .leading, spacing: 14) {
                Text("RACHA ACTUAL")
                    .font(AppFont.formSectionText2)
                    .fontWeight(.semibold)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(currentStreak)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))

                    Text("días")
                        .font(AppFont.subtitle)
                }

                Text(flavorText)
                    .font(AppFont.captionApp)
                    .fontWeight(.medium)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .frame(maxWidth: .infinity, minHeight: 178)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
    }

    private var flavorText: String {
        if currentStreak == 0 {
            return "Empieza hoy para arrancar tu racha."
        }

        if currentStreak == bestStreak {
            return "Tu mejor marca hasta ahora · nunca lo habías logrado."
        }

        return "Sigue así para alcanzar tu récord de \(bestStreak) días."
    }
}

#Preview {
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
    .padding()
    .background(AppColor.bgLight)
}
