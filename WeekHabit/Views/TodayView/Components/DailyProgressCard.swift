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
    let streakDays: Int

    private var headline: String {
        if totalCount == 0 {
            return "Hoy también puede ser descanso."
        }

        if remainingCount == 0 {
            return "Día cerrado con calma."
        }

        if completedCount == 0 {
            return "Volver empieza con una marca."
        }

        return "Estás volviendo, eso ya cuenta."
    }

    private var statusText: String {
        if remainingCount == 0 {
            return "CERRADO"
        }

        return "VOLVIENDO"
    }

    private var displayStreakDays: Int {
        max(streakDays, completedCount > 0 ? 1 : 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(headline)
                .font(.system(size: 21, weight: .semibold, design: .serif).italic())
                .foregroundStyle(AppColor.strongText)
                .lineLimit(2)
                .minimumScaleFactor(0.88)

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(completedCount)")
                            .font(.system(size: 31, weight: .semibold, design: .default))
                            .foregroundStyle(AppColor.strongText)
                            .monospacedDigit()

                        Text("de \(totalCount) hoy")
                            .font(AppFont.captionApp)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColor.mutedText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.84)
                    }

                    TodayProgressSegments(
                        progress: progress,
                        totalCount: totalCount,
                        completedCount: completedCount
                    )
                    .frame(height: 5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(AppColor.surfaceMuted)
                    .frame(width: 1, height: 56)

                VStack(alignment: .center, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(displayStreakDays)")
                            .font(.system(size: 31, weight: .semibold, design: .default))
                            .foregroundStyle(AppColor.strongText)
                            .monospacedDigit()

                        Text("días")
                            .font(AppFont.formSectionText)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColor.mutedText)
                    }

                    Text(statusText)
                        .font(AppFont.formSectionText)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColor.mutedText)
                        .tracking(0.8)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .frame(width: 94)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, minHeight: 142, alignment: .leading)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: "#e8dcc8"), lineWidth: 1)
        }
    }
}

private struct TodayProgressSegments: View {
    let progress: Double
    let totalCount: Int
    let completedCount: Int

    private var segmentCount: Int {
        min(max(totalCount, 1), 5)
    }

    private var filledCount: Int {
        guard totalCount > 0 else { return 0 }
        let raw = Int((progress * Double(segmentCount)).rounded(.up))
        return min(max(raw, completedCount > 0 ? 1 : 0), segmentCount)
    }

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<segmentCount, id: \.self) { index in
                Capsule()
                    .fill(index < filledCount ? AppColor.accent : AppColor.surfaceMuted)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityLabel("\(completedCount) de \(totalCount) hábitos completados hoy")
    }
}

#Preview {
    DailyProgressCard(
        progress: 0.33,
        completedCount: 1,
        totalCount: 3,
        remainingCount: 2,
        streakDays: 7
    )
    .padding()
    .background(AppColor.bgLight)
}
