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
