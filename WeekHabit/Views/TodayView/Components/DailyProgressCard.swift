//
//  DailyProgressCard.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 28/04/26.
//

import SwiftUI

struct DailyProgressCard: View {
    let progress: Double
    let completedCount: Int
    let totalCount: Int
    let remainingCount: Int

    private var progressPercent: Int {
        Int((progress * 100).rounded())
    }

    private var footerText: String {
        if totalCount == 0 {
            return "Sin hábitos para hoy"
        }

        if remainingCount == 0 {
            return "Día cerrado"
        }

        return "Te faltan \(remainingCount) para cerrar el día"
    }

    var body: some View {
        HStack(spacing: 22) {
            DailyProgressRing(
                progress: progress,
                percent: progressPercent
            )

            VStack(alignment: .leading, spacing: 5) {
                Text("HOY")
                    .font(AppFont.formSectionText2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColor.mutedText)

                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(completedCount)")
                        .font(.system(size: 27, weight: .semibold, design: .serif))
                        .foregroundStyle(AppColor.accent)

                    Text("/ \(totalCount)")
                        .font(.system(size: 27, weight: .regular, design: .serif))
                        .foregroundStyle(AppColor.mutedText)
                }

                Text(footerText)
                    .font(AppFont.formSectionText2)
                    .foregroundStyle(AppColor.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, minHeight: 122, alignment: .leading)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

#Preview {
    DailyProgressCard(
        progress: 0.75,
        completedCount: 3,
        totalCount: 4,
        remainingCount: 1
    )
    .padding()
    .background(AppColor.bgLight)
}
