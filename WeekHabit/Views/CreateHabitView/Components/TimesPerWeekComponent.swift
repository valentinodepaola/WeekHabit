//
//  TimesPerWeekComponent.swift
//  WeekHabit
//

import SwiftUI

struct TimesPerWeekComponent: View {
    @Binding var timesPerWeek: Int

    var body: some View {
        HStack {
            Text("\(timesPerWeek)")
                .font(AppFont.subtitle)
                .padding(.leading)

            Text(timesPerWeek == 1 ? "vez/semana" : "veces/semana")
                .font(AppFont.captionApp)
                .foregroundStyle(AppColor.subtleText)

            Spacer()

            stepButton(icon: "minus", isPrimary: false) {
                if timesPerWeek > 1 {
                    timesPerWeek -= 1
                }
            }

            stepButton(icon: "plus", isPrimary: true) {
                if timesPerWeek < 7 {
                    timesPerWeek += 1
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.pill, style: .continuous))
    }

    private func stepButton(icon: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundStyle(isPrimary ? .white : .black)
                .fontWeight(.bold)
        }
        .frame(width: 15, height: 15)
        .padding()
        .background(isPrimary ? AppColor.accent : AppColor.surfaceMuted)
        .clipShape(Circle())
    }
}
