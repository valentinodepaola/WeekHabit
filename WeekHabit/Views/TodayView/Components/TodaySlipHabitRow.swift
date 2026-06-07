//
//  TodaySlipHabitRow.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 06/06/26.
//

import SwiftUI

struct TodaySlipHabitRow: View {
    let habit: Habit
    let metadata: String
    let onEdit: () -> Void
    let onUndo: () -> Void
    var onOpenDetail: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.m) {
            HStack(alignment: .center, spacing: AppSpacing.m) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColor.warning)
                    .frame(width: 32, height: 32)
                    .background(AppColor.warning.opacity(0.13))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                            .strokeBorder(AppColor.warning.opacity(0.34), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(habit.title)
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)

                    Text(metadata)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onOpenDetail?()
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Ver detalle")

            HStack(spacing: AppSpacing.xs) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColor.editAction)
                        .frame(width: 32, height: 32)
                        .background(AppColor.editAction.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Editar contexto de \(habit.title)")

                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColor.warning)
                        .frame(width: 32, height: 32)
                        .background(AppColor.warning.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Deshacer slip de \(habit.title)")
            }
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.vertical, AppSpacing.m)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .strokeBorder(AppColor.warning.opacity(0.20), lineWidth: 1)
        }
    }
}
