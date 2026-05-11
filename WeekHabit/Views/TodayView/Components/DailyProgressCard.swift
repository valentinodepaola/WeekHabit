//
//  DailyProgressCard.swift
//  WeekHabit
//

import SwiftUI

struct DailyProgressCard: View {
    let progress: Double
    let completedCount: Int
    let totalCount: Int
    let remainingCount: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var completionBlend: Double {
        totalCount > 0 && remainingCount == 0 ? 1 : 0
    }

    private var headlineText: String {
        if totalCount == 0 { return "Sin hábitos hoy" }
        if remainingCount == 0 { return "Día cerrado" }
        if remainingCount == 1 { return "Te falta uno" }
        return "Te faltan \(remainingCount)"
    }

    private var supportText: String {
        if totalCount == 0 {
            return "El descanso también construye semana."
        }
        if remainingCount == 0 {
            return "Llegaste a tu meta de hoy."
        }
        return "Un paso pequeño cuenta."
    }

    var body: some View {
        WHCard(variant: .elevated, padding: AppSpacing.l, radius: AppRadius.l) {
            HStack(spacing: AppSpacing.l) {
                WHProgressRing(
                    progress: progress,
                    lineWidth: 8,
                    size: 86,
                    progressColor: AppColor.accent
                ) {
                    VStack(spacing: 0) {
                        Text("\(completedCount)")
                            .font(.system(size: 22, weight: .regular, design: .serif))
                            .foregroundStyle(AppColor.textPrimary)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("de \(totalCount)")
                            .font(AppFont.label)
                            .foregroundStyle(AppColor.textTertiary)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                }
                .todayProgressCompletionOverlay(
                    progress: progress,
                    lineWidth: 8,
                    completionBlend: completionBlend,
                    reduceMotion: reduceMotion
                )

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("HOY")
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)
                        .tracking(1)

                    Text(headlineText)
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.textPrimary)
                        .contentTransition(.opacity)

                    Text(supportText)
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                }

                Spacer(minLength: 0)
            }
        }
        .animation(AppMotion.respectful(AppMotion.gentle, reduceMotion), value: progress)
        .animation(AppMotion.respectful(.easeInOut(duration: 0.5), reduceMotion), value: completionBlend)
    }
}

private extension View {
    func todayProgressCompletionOverlay(
        progress: Double,
        lineWidth: CGFloat,
        completionBlend: Double,
        reduceMotion: Bool
    ) -> some View {
        overlay {
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(
                    AppColor.success,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .opacity(completionBlend)
                .scaleEffect(CGFloat(0.98 + (0.02 * completionBlend)))
                .animation(AppMotion.respectful(AppMotion.gentle, reduceMotion), value: progress)
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.m) {
        DailyProgressCard(progress: 0.66, completedCount: 2, totalCount: 3, remainingCount: 1)
        DailyProgressCard(progress: 1.0, completedCount: 3, totalCount: 3, remainingCount: 0)
        DailyProgressCard(progress: 0.0, completedCount: 0, totalCount: 0, remainingCount: 0)
    }
    .padding()
    .background(AppColor.bgCanvas)
}
