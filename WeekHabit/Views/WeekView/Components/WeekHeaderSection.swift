//
//  WeekHeaderSection.swift
//  WeekHabit
//

import SwiftUI

struct WeekHeaderSection: View {
    var monthYearLabel: String
    var weekNumber: Int
    @Binding var weekOffset: Int
    var onShowLegend: (() -> Void)? = nil
    var onCreate: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(monthYearLabel)
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(0.6)

            HStack(spacing: AppSpacing.m) {
                Text("Semana \(weekNumber)")
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.textPrimary)

                Spacer()

                if weekOffset != 0 {
                    Button("Hoy") {
                        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
                            weekOffset = 0
                        }
                    }
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.accent)
                    .padding(.horizontal, AppSpacing.m)
                    .padding(.vertical, AppSpacing.s)
                    .background(AppColor.accentMuted, in: Capsule())
                }

                HStack(spacing: AppSpacing.s) {
                    if let onShowLegend {
                        WHCircleButton(systemName: "questionmark") {
                            onShowLegend()
                        }
                        .accessibilityLabel("Ver leyenda de la semana")
                    }

                    WHCircleButton(systemName: "chevron.left") {
                        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
                            weekOffset -= 1
                        }
                    }

                    WHCircleButton(systemName: "chevron.right") {
                        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
                            weekOffset += 1
                        }
                    }
                    .disabled(weekOffset >= 0)

                    if let onCreate {
                        Button(action: onCreate) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(AppColor.accent)
                                .clipShape(Circle())
                                .appElevation(.low)
                        }
                        .accessibilityLabel("Nuevo")
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.top, AppSpacing.l)
        .padding(.bottom, AppSpacing.l)
    }
}
