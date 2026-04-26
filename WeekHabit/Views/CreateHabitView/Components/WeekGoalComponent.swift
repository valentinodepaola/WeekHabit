//
//  WeekGoalComponent.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 25/04/26.
//

import SwiftUI

struct WeekGoalComponent: View {
    @Binding var days: Int
    
    var body: some View {
        HStack {
            Text("\(self.days)")
                .font(AppFont.subtitle)
                .padding(.leading)
            Text("dias/semana")
                .font(AppFont.captionApp)
                .foregroundStyle(AppColor.subtleText)

            Spacer()

            Button {
                if self.days > 0 {
                    self.days -= 1
                }
            } label: {
                Image(systemName: "minus")
                    .foregroundStyle(.black)
                    .fontWeight(.bold)
            }
            .frame(width: 15, height: 15)
            .padding()
            .background(AppColor.surfaceMuted)
            .cornerRadius(AppRadius.pill)
            .accessibilityLabel("Disminuir días")

            Button {
                if self.days < 7 {
                    self.days += 1
                }
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(.white)
                    .fontWeight(.bold)
            }
            .frame(width: 15, height: 15)
            .padding()
            .background(AppColor.accent)
            .cornerRadius(AppRadius.pill)
            .accessibilityLabel("Aumentar días")
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(AppColor.surface)
        .cornerRadius(AppRadius.pill)

    }
}

#Preview {
    WeekGoalComponent(
        days: .constant(0)
    )
}
