//
//  FocusTimerCard.swift
//  WeekHabit
//

import SwiftUI

struct FocusTimerCard: View {
    let timeText: String
    let progress: Double?
    let selectedCount: Int
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text(timeText)
                    .font(.system(size: 66, weight: .regular, design: .serif))
                    .foregroundStyle(AppColor.strongText)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(selectedCount == 1 ? "1 hábito en enfoque" : "\(selectedCount) hábitos en enfoque")
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.mutedText)
            }

            if let progress {
                ProgressView(value: progress)
                    .tint(AppColor.accent)
            }

            Button {
                onFinish()
            } label: {
                Text("Terminar sesión")
                    .font(AppFont.body2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(AppColor.accent)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}
