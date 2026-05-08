//
//  TodayEmptyStateView.swift
//  WeekHabit
//

import SwiftUI

struct TodayEmptyStateView: View {
    let weekdayName: String
    let tomorrowHabitsCount: Int
    var onAddHabitForToday: () -> Void

    private var tomorrowSummary: String {
        switch tomorrowHabitsCount {
        case 0: return "Sin hábitos programados"
        case 1: return "1 hábito te espera"
        default: return "\(tomorrowHabitsCount) hábitos te esperan"
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            iconBadge

            VStack(spacing: AppSpacing.s) {
                headlineText
                Text("No hay hábitos programados para los \(weekdayName). El descanso también construye semana.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
                    .fixedSize(horizontal: false, vertical: true)
            }

            tomorrowCard

            Button(action: onAddHabitForToday) {
                Text("Añadir un hábito para hoy")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.accent)
                    .underline()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Añadir un hábito para hoy")
            .padding(.top, AppSpacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.l)
    }

    private var iconBadge: some View {
        Image(systemName: "moon.stars")
            .font(.system(size: 36, weight: .light))
            .foregroundStyle(AppColor.info)
            .frame(width: 96, height: 96)
            .background(
                Circle().fill(AppColor.infoMuted)
            )
    }

    private var headlineText: some View {
        (Text("Hoy toca ").font(AppFont.headline)
         + Text("descansar").font(AppFont.headline.italic())
            .foregroundColor(AppColor.accent))
            .foregroundStyle(AppColor.textPrimary)
    }

    private var tomorrowCard: some View {
        HStack(spacing: AppSpacing.m) {
            Image(systemName: "sun.max")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(AppColor.warning)
                .frame(width: 48, height: 48)
                .background(AppColor.warning.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("MAÑANA")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.8)

                Text(tomorrowSummary)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, AppSpacing.m)
        .padding(.horizontal, AppSpacing.l)
        .frame(maxWidth: 345)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .stroke(AppColor.divider, lineWidth: 1)
        }
    }
}

#Preview {
    TodayEmptyStateView(weekdayName: "martes", tomorrowHabitsCount: 3) {}
        .padding()
        .background(AppColor.bgCanvas)
}
