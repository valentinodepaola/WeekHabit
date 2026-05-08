//
//  WHProgressBar.swift
//  WeekHabit
//
//  Barra de progreso unificada. Reemplaza PlanProgressBar, WeekProgressBar y
//  los inline de Onboarding/FocusSession cuando se migren.
//

import SwiftUI

struct WHProgressBar: View {
    let progress: Double
    var trackColor: Color = AppColor.divider
    var progressColor: Color = AppColor.accent
    var height: CGFloat = 6
    /// Línea opcional indicando una meta (0..1).
    var goalMarker: Double? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clampedProgress: Double {
        min(1, max(0, progress))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(trackColor)

                Capsule()
                    .fill(progressColor)
                    .frame(width: clampedProgress * proxy.size.width)
                    .animation(AppMotion.respectful(AppMotion.smooth, reduceMotion), value: clampedProgress)

                if let goalMarker, goalMarker > 0 && goalMarker < 1 {
                    Rectangle()
                        .fill(AppColor.textTertiary.opacity(0.4))
                        .frame(width: 1.5, height: height + 4)
                        .offset(x: goalMarker * proxy.size.width)
                }
            }
        }
        .frame(height: height)
    }
}
