//
//  NoticeHourSuggestion.swift
//  WeekHabit
//
//  Un dato junto al selector, no una decisión: dice a qué hora suele completar el usuario y
//  ofrece llevarla al selector con un toque explícito. Ignorarlo no cuesta nada y no insiste.
//

import SwiftUI

struct NoticeHourSuggestion: View {
    let window: HourWindow
    let onApply: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: "clock")
                .font(AppFont.iconSmall)
                .foregroundStyle(AppColor.info)
                .frame(width: 32, height: 32)
                .background(AppColor.infoMuted)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppSpacing.s) {
                Text(DailyNotice.suggestionText(for: window))
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                WHButton(
                    title: DailyNotice.suggestionActionTitle(for: window),
                    variant: .secondary,
                    size: .compact,
                    fullWidth: false,
                    action: onApply
                )
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.m)
        .background(AppColor.bgSunken.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
    }
}
