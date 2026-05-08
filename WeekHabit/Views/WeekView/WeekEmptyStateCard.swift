//
//  WeekEmptyStateCard.swift
//  WeekHabit
//

import SwiftUI

struct WeekEmptyStateCard: View {
    var onCreate: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.l) {
            ZStack {
                Circle()
                    .fill(AppColor.accentMuted)
                    .frame(width: 72, height: 72)
                Image(systemName: "square.grid.3x2")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(AppColor.accent)
            }

            VStack(spacing: AppSpacing.s) {
                headlineText
                Text("Aún no hay marcas. La cuadrícula se irá llenando a medida que completes hábitos.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.l)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let onCreate {
                WHButton(title: "Crear un hábito", icon: "plus", variant: .primary, fullWidth: false, action: onCreate)
            }
        }
        .padding(.vertical, AppSpacing.xxl)
        .padding(.horizontal, AppSpacing.l)
        .frame(maxWidth: .infinity)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.l)
                .stroke(AppColor.divider, lineWidth: 1)
        }
    }

    private var headlineText: some View {
        (Text("Una semana ").font(AppFont.headline)
         + Text("por escribir").font(AppFont.headline.italic())
            .foregroundColor(AppColor.accent))
            .foregroundStyle(AppColor.textPrimary)
    }
}

#Preview {
    WeekEmptyStateCard()
}
