//
//  AppElevation.swift
//  WeekHabit
//
//  En modo oscuro la jerarquía la dan los fondos canvas/elevated/sunken: las
//  sombras casi no aparecen. En modo claro se aplican sombras suaves cálidas.
//

import SwiftUI

enum AppElevationLevel {
    case low
    case medium
    case high
}

private struct AppElevationModifier: ViewModifier {
    let level: AppElevationLevel
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.shadow(
            color: shadowColor,
            radius: shadowRadius,
            x: 0,
            y: shadowY
        )
    }

    private var shadowColor: Color {
        let opacity: Double
        switch (colorScheme, level) {
        case (.dark, .low): opacity = 0.18
        case (.dark, .medium): opacity = 0.28
        case (.dark, .high): opacity = 0.4
        case (_, .low): opacity = 0.06
        case (_, .medium): opacity = 0.1
        case (_, .high): opacity = 0.16
        }
        return Color.black.opacity(opacity)
    }

    private var shadowRadius: CGFloat {
        switch level {
        case .low: return 4
        case .medium: return 12
        case .high: return 24
        }
    }

    private var shadowY: CGFloat {
        switch level {
        case .low: return 1
        case .medium: return 4
        case .high: return 10
        }
    }
}

extension View {
    /// Aplica una sombra coherente con el modo claro/oscuro del sistema.
    func appElevation(_ level: AppElevationLevel) -> some View {
        modifier(AppElevationModifier(level: level))
    }
}
