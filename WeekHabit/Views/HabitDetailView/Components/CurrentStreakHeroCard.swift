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
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Text("CONSTANCIA ACTUAL")
                    .font(AppFont.formSectionText2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.mutedText)
                    .tracking(1.1)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(currentStreak)")
                        .font(.system(size: 52, weight: .semibold, design: .default))
                        .foregroundStyle(AppColor.strongText)
                        .monospacedDigit()

                    Text("días")
                        .font(AppFont.subtitle3)
                        .foregroundStyle(AppColor.mutedText)
                }

                Text(flavorText)
                    .font(.system(size: 18, weight: .semibold, design: .serif).italic())
                    .foregroundStyle(AppColor.strongText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 164, alignment: .leading)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: "#e8dcc8"), lineWidth: 1)
        }
    }

    private var flavorText: String {
        if currentStreak == 0 {
            return "Hoy también cuenta. Vuelve con una marca pequeña."
        }

        if currentStreak == bestStreak {
            return "Estás construyendo una referencia nueva, día a día."
        }

        return "Cada día que vuelves cuenta. Tu referencia: \(bestStreak) días."
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
