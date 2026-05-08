//
//  WHProgressRing.swift
//  WeekHabit
//
//  Anillo de progreso unificado. Reemplaza implementaciones ad-hoc en
//  DailyProgressCard, FocusTimerCard y WeekView.
//

import SwiftUI

struct WHProgressRing<Center: View>: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    var size: CGFloat = 96
    var trackColor: Color = AppColor.divider
    var progressColor: Color = AppColor.accent
    @ViewBuilder let center: () -> Center

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clampedProgress: Double {
        min(1, max(0, progress))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, style: StrokeStyle(lineWidth: lineWidth))

            Circle()
                .trim(from: 0, to: max(0.001, clampedProgress))
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(AppMotion.respectful(AppMotion.smooth, reduceMotion), value: clampedProgress)

            center()
                .padding(lineWidth + AppSpacing.s)
        }
        .frame(width: size, height: size)
    }
}

extension WHProgressRing where Center == EmptyView {
    init(
        progress: Double,
        lineWidth: CGFloat = 10,
        size: CGFloat = 96,
        trackColor: Color = AppColor.divider,
        progressColor: Color = AppColor.accent
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.trackColor = trackColor
        self.progressColor = progressColor
        self.center = { EmptyView() }
    }
}
