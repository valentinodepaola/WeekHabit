//
//  TodayHeaderSection.swift
//  WeekHabit
//

import SwiftUI

struct TodayHeaderSection: View {
    let dateTitle: String
    let onCreateTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.m) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(dateTitle)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.6)

                Text("Hoy")
                    .font(AppFont.title.bold())
                    .foregroundStyle(AppColor.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onCreateTap) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(AppColor.accent)
                    .clipShape(Circle())
                    .appElevation(.low)
            }
            .accessibilityLabel("Crear")
        }
    }
}
