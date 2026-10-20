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

#if DEBUG
/// Solo descanso y "sin hábitos": son los estados que dibujan glifo en vez de anillo, en los
/// dos tamaños con que lo usan `systemSmall` y `systemMedium`.
#Preview("Glifo · descanso y sin hábitos") {
    VStack(spacing: AppSpacing.l) {
        ForEach([TodayWidgetState.rest, .empty], id: \.self) { state in
            HStack(spacing: AppSpacing.l) {
                TodayWidgetGlyph(state: state, size: 76)
                TodayWidgetGlyph(state: state, size: 92)
            }
        }
    }
    .padding()
    .background(AppColor.bgElevated)
}
#endif
