//
//  SplashDayNode.swift
//  WeekHabit
//

import SwiftUI

struct SplashDayNode: View {
    let weekday: Weekday
    let index: Int
    let progress: CGFloat

    private var activationThreshold: CGFloat {
        CGFloat(index + 1) / CGFloat(Weekday.ordered.count) - 0.04
    }

    private var isActive: Bool {
        progress >= activationThreshold
    }

    private var color: Color {
        SplashRhythmPalette.colors[index % SplashRhythmPalette.colors.count]
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                .fill(isActive ? color : AppColor.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                        .stroke(
                            isActive ? color.opacity(0.28) : AppColor.subtleText.opacity(0.18),
                            lineWidth: 1
                        )
                }

            if isActive {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Text(weekday.oneLetterName)
                    .font(.system(size: 12, weight: .bold, design: .default))
                    .foregroundStyle(AppColor.subtleText)
            }
        }
        .frame(width: 30, height: 38)
        .scaleEffect(isActive ? 1 : 0.86)
        .shadow(color: isActive ? color.opacity(0.22) : Color.clear, radius: 8, x: 0, y: 5)
        .animation(SplashScreenMotion.dayNode(index: index), value: isActive)
    }
}

