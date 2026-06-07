//
//  TodayFreezeBanner.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 06/06/26.
//

import SwiftUI

struct TodayFreezeBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: "shield.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColor.info)
                .frame(width: 30, height: 30)
                .background(AppColor.info.opacity(0.14))
                .clipShape(Circle())

            Text(message)
                .font(AppFont.label)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.m)
        .padding(.vertical, AppSpacing.s)
        .background(AppColor.info.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .strokeBorder(AppColor.info.opacity(0.22), lineWidth: 1)
        }
    }
}
