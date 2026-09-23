//
//  FocusSessionLiveActivity.swift
//  WeekHabitWidgets
//
//  Live Activity de la Sesión de ritmo: pantalla bloqueada e Isla Dinámica.
//
//  La app no puede actualizarla con el teléfono bloqueado, así que todo lo que se mueve lo
//  anima el sistema a partir de las fechas del `ContentState`: `Text(timerInterval:)` para la
//  cifra y `ProgressView(timerInterval:)` para el anillo. Cuando pasa la hora de fin, el
//  sistema la marca como vieja (`staleDate`) y la vista lo dice en vez de quedarse en 0:00.
//
//  Sin `widgetURL`: tocarla abre la app, donde la sesión sigue presentada.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct FocusSessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusSessionActivityAttributes.self) { context in
            FocusActivityLockScreenView(
                attributes: context.attributes,
                state: context.state,
                isStale: context.isStale
            )
            .activityBackgroundTint(AppColor.bgElevated)
            .activitySystemActionForegroundColor(AppColor.accent)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    FocusActivityGlyph(state: context.state, isStale: context.isStale, size: 44)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    FocusActivityTime(state: context.state, isStale: context.isStale)
                        .font(AppFont.dataMetric.monospacedDigit())
                        .foregroundStyle(AppColor.textPrimary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.isStale ? FocusSessionCopy.finishedDetail : context.attributes.subtitle)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(AppColor.accent)
            } compactTrailing: {
                FocusActivityTime(state: context.state, isStale: context.isStale)
                    .font(AppFont.label.monospacedDigit())
                    .foregroundStyle(AppColor.accent)
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(AppColor.accent)
            }
            .keylineTint(AppColor.accent)
        }
    }
}

/// Pantalla bloqueada: anillo, qué está en enfoque y la cifra grande.
struct FocusActivityLockScreenView: View {
    let attributes: FocusSessionActivityAttributes
    let state: FocusSessionActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            FocusActivityGlyph(state: state, isStale: isStale, size: 48)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(FocusSessionCopy.activityTitle)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.textPrimary)
                // Dos líneas: con "Terminó" a la derecha, la frase de cierre no entraba en una.
                Text(isStale ? FocusSessionCopy.finishedDetail : attributes.subtitle)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppSpacing.s)

            FocusActivityTime(state: state, isStale: isStale)
                .font(AppFont.dataMetric.monospacedDigit())
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 110, alignment: .trailing)
        }
        .padding(AppSpacing.l)
    }
}

/// La cifra: cuenta regresiva con duración, cronómetro en una sesión libre, "Terminó" cuando
/// pasó la hora y la app todavía no la cerró.
struct FocusActivityTime: View {
    let state: FocusSessionActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        if isStale, state.endDate != nil {
            Text(FocusSessionCopy.finishedLabel)
        } else if let endDate = state.endDate {
            Text(timerInterval: state.startDate...endDate, countsDown: true)
        } else {
            Text(state.startDate, style: .timer)
        }
    }
}

/// Anillo que se vacía con la sesión, el mismo gesto que `FocusTimerRing` en la app. Una
/// sesión libre no tiene cuánto falta: lleva el ícono del temporizador en su lugar.
struct FocusActivityGlyph: View {
    let state: FocusSessionActivityAttributes.ContentState
    let isStale: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColor.accentMuted)

            if let endDate = state.endDate, !isStale {
                ProgressView(timerInterval: state.startDate...endDate, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .progressViewStyle(.circular)
                .tint(AppColor.accent)
                .padding(4)
            }

            Image(systemName: isStale ? "checkmark" : "timer")
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(AppColor.accent)
        }
        .frame(width: size, height: size)
    }
}

#Preview("Con duración", as: .content, using: FocusSessionActivityAttributes(
    sessionID: UUID(),
    habitCount: 3,
    isSequenced: true
)) {
    FocusSessionLiveActivity()
} contentStates: {
    FocusSessionActivityAttributes.ContentState(
        startDate: .now,
        endDate: .now.addingTimeInterval(25 * 60)
    )
    FocusSessionActivityAttributes.ContentState(startDate: .now, endDate: nil)
}
