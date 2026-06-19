//
//  WeekRhythmHero.swift
//  WeekHabit
//
//  Héroe de la primera pantalla del onboarding: ondas de ritmo respirando y
//  los 7 días de la semana encendiéndose uno a uno alrededor del centro.
//  Un día queda "sostenido" (relleno suave, sin completar) como guiño al
//  comodín — la semana avanza aunque un día no sea perfecto.
//

import SwiftUI

struct WeekRhythmHero: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let rings: [CGFloat] = [1.0, 0.82, 0.65, 0.5]
    private let baseSize: CGFloat = 240
    private let dayCount = 7
    /// Día que se sostiene con el comodín en la animación.
    private let heldDayIndex = 4
    /// Radio de la órbita de los días: coincide con el segundo anillo.
    private var orbitRadius: CGFloat { baseSize * 0.82 / 2 }

    @State private var isBreathing = false

    var body: some View {
        ZStack {
            ZStack {
                ringsLayer
                daysLayer
            }
            .scaleEffect(isBreathing ? 1.04 : 1)

            orb
                .scaleEffect(isBreathing ? 1.08 : 1)
        }
        .frame(width: baseSize, height: baseSize)
        .onAppear {
            guard !reduceMotion else { return }
            // Respiración ambiental continua; no es una transición de estado,
            // por eso no usa los springs de AppMotion.
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Una semana completándose a su propio ritmo")
    }

    private var ringsLayer: some View {
        ForEach(rings.indices, id: \.self) { index in
            Circle()
                .stroke(AppColor.accent, lineWidth: 1.5)
                .frame(width: baseSize * rings[index], height: baseSize * rings[index])
                .opacity(Double(rings.count - index) * 0.12 + 0.06)
        }
    }

    @ViewBuilder
    private var daysLayer: some View {
        if reduceMotion {
            dayDots(litCount: dayCount)
        } else {
            // Fases 0...dayCount encienden un día por paso; la fase extra al
            // final sostiene la semana completa antes de reiniciar.
            PhaseAnimator(Array(0...(dayCount + 1))) { phase in
                dayDots(litCount: min(phase, dayCount))
            } animation: { phase in
                phase == 0
                    ? .easeOut(duration: 0.5).delay(1.4)
                    : AppMotion.snap.delay(0.32)
            }
        }
    }

    private func dayDots(litCount: Int) -> some View {
        ForEach(0..<dayCount, id: \.self) { index in
            dayDot(index: index, isLit: index < litCount)
                .offset(y: -orbitRadius)
                .rotationEffect(.degrees(Double(index) / Double(dayCount) * 360))
        }
    }

    private func dayDot(index: Int, isLit: Bool) -> some View {
        let isHeld = index == heldDayIndex

        return Circle()
            .fill(dotFill(isLit: isLit, isHeld: isHeld))
            .overlay {
                Circle()
                    .strokeBorder(
                        isLit ? AppColor.accent : AppColor.accent.opacity(0.28),
                        lineWidth: isLit && isHeld ? 1.5 : 1
                    )
            }
            .frame(width: 13, height: 13)
            .scaleEffect(isLit ? 1 : 0.78)
    }

    private func dotFill(isLit: Bool, isHeld: Bool) -> Color {
        guard isLit else { return .clear }
        return isHeld ? AppColor.accentMuted : AppColor.accent
    }

    private var orb: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [AppColor.accent.opacity(0.88), AppColor.accent],
                    center: UnitPoint(x: 0.38, y: 0.3),
                    startRadius: 2,
                    endRadius: 46
                )
            )
            .frame(width: 64, height: 64)
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
            }
    }
}

#Preview {
    AppBackground {
        WeekRhythmHero()
    }
}
