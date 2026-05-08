//
//  WHSectionHeader.swift
//  WeekHabit
//
//  Encabezado de sección: título + subtítulo opcional + acción opcional.
//

import SwiftUI

struct WHSectionHeaderAction {
    let label: String
    let perform: () -> Void
}

struct WHSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: WHSectionHeaderAction? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.m) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            Spacer(minLength: AppSpacing.s)

            if let action {
                Button(action.label, action: action.perform)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.accent)
            }
        }
    }
}
