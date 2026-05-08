//
//  WHCard.swift
//  WeekHabit
//
//  Contenedor unificado del sistema. Tres densidades: flat, elevated, sunken.
//

import SwiftUI

enum WHCardVariant {
    /// Mismo color que el canvas: agrupa contenido sin destacarlo.
    case flat
    /// Un escalón arriba: cards principales (default).
    case elevated
    /// Hundido: inputs, áreas que reciben contenido.
    case sunken
}

struct WHCard<Content: View>: View {
    var variant: WHCardVariant = .elevated
    var padding: CGFloat = AppSpacing.l
    var radius: CGFloat = AppRadius.l
    let content: Content

    init(
        variant: WHCardVariant = .elevated,
        padding: CGFloat = AppSpacing.l,
        radius: CGFloat = AppRadius.l,
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.padding = padding
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .modifier(ElevationIfNeeded(variant: variant))
    }

    private var backgroundColor: Color {
        switch variant {
        case .flat: return AppColor.bgCanvas
        case .elevated: return AppColor.bgElevated
        case .sunken: return AppColor.bgSunken
        }
    }
}

private struct ElevationIfNeeded: ViewModifier {
    let variant: WHCardVariant

    func body(content: Content) -> some View {
        switch variant {
        case .elevated:
            content.appElevation(.low)
        case .flat, .sunken:
            content
        }
    }
}
