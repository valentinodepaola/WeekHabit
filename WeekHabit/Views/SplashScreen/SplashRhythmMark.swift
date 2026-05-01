//
//  SplashRhythmMark.swift
//  WeekHabit
//

import SwiftUI

struct SplashRhythmMark: View {
    let progress: CGFloat
    let pulseIsExpanded: Bool
    let contentIsVisible: Bool

    private let ringSize: CGFloat = 188
    private let nodeRadius: CGFloat = 94

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                SplashPulseRing(
                    index: index,
                    isExpanded: pulseIsExpanded,
                    isVisible: contentIsVisible
                )
            }

            Circle()
                .stroke(AppColor.subtleText.opacity(0.13), lineWidth: 9)
                .frame(width: ringSize, height: ringSize)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppColor.accent,
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: ringSize, height: ringSize)
                .shadow(color: AppColor.accent.opacity(0.22), radius: 9, x: 0, y: 7)

            ForEach(Weekday.ordered.indices, id: \.self) { index in
                let angle = Double(index) / Double(Weekday.ordered.count) * 360

                SplashDayNode(
                    weekday: Weekday.ordered[index],
                    index: index,
                    progress: progress
                )
                .rotationEffect(.degrees(-angle))
                .offset(y: -nodeRadius)
                .rotationEffect(.degrees(angle))
            }

            SplashCoreIcon(isExpanded: pulseIsExpanded)
        }
        .frame(width: 250, height: 250)
    }
}

