//
//  InsightCardStyle.swift
//  WeekHabit
//

import SwiftUI

private struct InsightCardModifier: ViewModifier {
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let cornerRadius: CGFloat
    let background: Color
    let elevation: AppElevationLevel?

    func body(content: Content) -> some View {
        let card = content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

        if let elevation {
            card.appElevation(elevation)
        } else {
            card
        }
    }
}

extension View {
    func insightCard(
        padding: CGFloat = AppSpacing.l,
        cornerRadius: CGFloat = AppRadius.l,
        background: Color = AppColor.bgElevated,
        elevation: AppElevationLevel? = .low
    ) -> some View {
        insightCard(
            horizontalPadding: padding,
            verticalPadding: padding,
            cornerRadius: cornerRadius,
            background: background,
            elevation: elevation
        )
    }

    func insightCard(
        horizontalPadding: CGFloat,
        verticalPadding: CGFloat,
        cornerRadius: CGFloat = AppRadius.l,
        background: Color = AppColor.bgElevated,
        elevation: AppElevationLevel? = .low
    ) -> some View {
        modifier(
            InsightCardModifier(
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding,
                cornerRadius: cornerRadius,
                background: background,
                elevation: elevation
            )
        )
    }
}

#Preview {
    VStack(spacing: AppSpacing.m) {
        Text("Tarjeta de Insights")
            .font(AppFont.bodyEmphasis)
            .frame(maxWidth: .infinity, alignment: .leading)
            .insightCard()

        Text("Sin elevación, con fondo de información")
            .font(AppFont.bodyEmphasis)
            .frame(maxWidth: .infinity, alignment: .leading)
            .insightCard(background: AppColor.infoMuted.opacity(0.5), elevation: nil)

        Text("Padding horizontal y vertical distintos")
            .font(AppFont.bodyEmphasis)
            .frame(maxWidth: .infinity, alignment: .leading)
            .insightCard(horizontalPadding: AppSpacing.l, verticalPadding: AppSpacing.s)
    }
    .padding()
    .background(AppColor.bgCanvas)
}
