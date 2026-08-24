//
//  TodayWidgetGlyph.swift
//  WeekHabitWidgets
//

import SwiftUI

/// El símbolo en su círculo suave, para los estados que no dibujan anillo.
///
/// Es su propia vista porque lo comparten `systemSmall` y `systemMedium`, y porque el tamaño
/// del glifo respecto del círculo es una proporción que conviene que no se reinvente en cada
/// familia.
struct TodayWidgetGlyph: View {
    let state: TodayWidgetState
    var size: CGFloat = 76

    var body: some View {
        Circle()
            .fill(state.mutedTint)
            .frame(width: size, height: size)
            .overlay {
                if let symbolName = state.symbolName {
                    Image(systemName: symbolName)
                        .font(.system(size: size * 0.38, weight: .semibold))
                        .foregroundStyle(state.tint)
                }
            }
    }
}
