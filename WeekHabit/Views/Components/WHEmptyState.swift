//
//  WHEmptyState.swift
//  WeekHabit
//
//  Empty state unificado. Reemplaza TodayEmptyStateView, WeekEmptyStateCard y
//  los empty inline de Insights cuando se migren.
//

import SwiftUI

struct WHEmptyStateAction {
    let label: String
    let perform: () -> Void
}

struct WHEmptyState: View {
    let icon: String
    let title: String
    var message: String? = nil
    var primaryAction: WHEmptyStateAction? = nil
    var secondaryAction: WHEmptyStateAction? = nil

    var body: some View {
        VStack(spacing: AppSpacing.l) {
            iconBadge
            VStack(spacing: AppSpacing.s) {
                Text(title)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.center)
                if let message {
                    Text(message)
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if primaryAction != nil || secondaryAction != nil {
                actions
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.xxl)
    }

    private var iconBadge: some View {
        Image(systemName: icon)
            .font(.system(size: 36, weight: .light))
            .foregroundStyle(AppColor.accent)
            .frame(width: 88, height: 88)
            .background(
                Circle().fill(AppColor.accentMuted)
            )
    }

    @ViewBuilder
    private var actions: some View {
        VStack(spacing: AppSpacing.s) {
            if let primaryAction {
                WHButton(title: primaryAction.label, variant: .primary, fullWidth: false, action: primaryAction.perform)
            }
            if let secondaryAction {
                WHButton(title: secondaryAction.label, variant: .ghost, fullWidth: false, action: secondaryAction.perform)
            }
        }
        .frame(maxWidth: 280)
    }
}
