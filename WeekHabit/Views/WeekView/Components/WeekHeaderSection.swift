//
//  WeekHeaderSection.swift
//  WeekHabit
//

import SwiftUI

struct WeekHeaderSection: View {
    var monthYearLabel: String
    var weekNumber: Int
    @Binding var weekOffset: Int
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
                    navButton(systemName: "chevron.left") {
                        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
                            weekOffset -= 1
                        }
                    }

                    navButton(systemName: "chevron.right") {
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

private func navButton(systemName: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppColor.textPrimary)
            .frame(width: 40, height: 40)
            .background(AppColor.bgElevated)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(AppColor.divider, lineWidth: 1)
            }
    }
    .buttonStyle(.plain)
}
