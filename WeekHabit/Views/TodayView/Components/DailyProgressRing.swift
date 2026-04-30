//
//  DailyProgressRing.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 28/04/26.
//

import SwiftUI

struct DailyProgressRing: View {
    let progress: Double
    let percent: Int

    private var normalizedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColor.subtleText.opacity(0.14), lineWidth: 6)

            Circle()
                .trim(from: 0, to: normalizedProgress)
                .stroke(
                    AppColor.accent,
                    style: StrokeStyle(
                        lineWidth: 6,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("\(percent)")
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundStyle(AppColor.strongText)

                Text("%")
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .foregroundStyle(AppColor.mutedText)
            }
        }
        .frame(width: 78, height: 78)
    }
}

#Preview {
    DailyProgressRing(
        progress: 0.75,
        percent: 75
    )
    .padding()
    .background(AppColor.bgLight)
}
