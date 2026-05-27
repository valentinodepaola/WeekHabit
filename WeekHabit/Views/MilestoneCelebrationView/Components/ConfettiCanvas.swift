//
//  ConfettiCanvas.swift
//  WeekHabit
//

import SwiftUI

struct ConfettiCanvas: View {
    let seed: UInt64
    let habitColor: Color
    let reduceMotion: Bool

    @State private var startDate = Date()
    @State private var didFinish = false

    private let particles: [Particle]

    init(seed: UInt64, habitColor: Color, reduceMotion: Bool) {
        self.seed = seed
        self.habitColor = habitColor
        self.reduceMotion = reduceMotion
        self.particles = Self.makeParticles(seed: seed, habitColor: habitColor)
    }

    var body: some View {
        Group {
            if reduceMotion {
                StaticCelebrationDots(habitColor: habitColor)
            } else if didFinish {
                Color.clear
            } else {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(startDate)

                    Canvas { context, size in
                        drawParticles(in: context, size: size, elapsed: elapsed)
                    }
                    .onChange(of: timeline.date) { _, date in
                        markFinishedIfNeeded(elapsed: date.timeIntervalSince(startDate))
                    }
                }
            }
        }
    }

    private func drawParticles(in context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let gravity: CGFloat = 380

        for particle in particles {
            let t = CGFloat(elapsed)
            let x = particle.origin.x * size.width + particle.velocity.dx * t
            let y = particle.origin.y * size.height + particle.velocity.dy * t + 0.5 * gravity * t * t
            guard y < size.height + 80, x > -80, x < size.width + 80 else { continue }

            let fadeStart: CGFloat = 2.5
            let opacity = t <= fadeStart ? 1 : max(0, 1 - ((t - fadeStart) / 1.3))
            guard opacity > 0 else { continue }

            var particleContext = context
            particleContext.translateBy(x: x, y: y)
            particleContext.rotate(by: .radians(particle.rotation + particle.spin * elapsed))
            particleContext.fill(
                particle.shape.path(size: particle.size),
                with: .color(particle.color.opacity(opacity))
            )
        }
    }

    private func markFinishedIfNeeded(elapsed: TimeInterval) {
        guard elapsed >= 4, !didFinish else { return }
        didFinish = true
    }

    private static func makeParticles(seed: UInt64, habitColor: Color) -> [Particle] {
        var generator = SeededGenerator(seed: seed == 0 ? 1 : seed)
        let palette = [
            habitColor,
            habitColor.opacity(0.72),
            AppColor.accent,
            AppColor.success,
            AppColor.warning.opacity(0.84),
            Color.white.opacity(0.9)
        ]
        let emitters: [(x: CGFloat, y: CGFloat, spread: ClosedRange<Double>)] = [
            (0.5, 1.04, -130...130),
            (0.14, 1.02, 20...220),
            (0.86, 1.02, -220...(-20))
        ]

        return (0..<180).map { index in
            let emitter = emitters[index % emitters.count]
            let speedY = generator.nextDouble(in: -690...(-380))
            let drift = generator.nextDouble(in: emitter.spread)
            let delayedY = generator.nextDouble(in: 0...90)

            return Particle(
                origin: CGPoint(x: emitter.x, y: emitter.y + CGFloat(delayedY / 900)),
                velocity: CGVector(dx: drift, dy: speedY),
                color: palette[index % palette.count],
                rotation: generator.nextDouble(in: 0...(Double.pi * 2)),
                shape: ParticleShape.allCases[index % ParticleShape.allCases.count],
                spin: generator.nextDouble(in: -7...7),
                size: CGFloat(generator.nextDouble(in: 6...13))
            )
        }
    }
}

private struct Particle {
    var origin: CGPoint
    var velocity: CGVector
    var color: Color
    var rotation: Double
    var shape: ParticleShape
    var spin: Double
    var size: CGFloat
}

private enum ParticleShape: CaseIterable {
    case circle
    case rectangle
    case capsule
    case triangle

    func path(size: CGFloat) -> Path {
        switch self {
        case .circle:
            return Path(ellipseIn: CGRect(x: -size / 2, y: -size / 2, width: size, height: size))
        case .rectangle:
            return Path(CGRect(x: -size / 2, y: -size / 3, width: size, height: size * 0.66))
        case .capsule:
            return Path(roundedRect: CGRect(x: -size / 2, y: -size / 4, width: size * 1.4, height: size * 0.5), cornerRadius: size * 0.25)
        case .triangle:
            var path = Path()
            path.move(to: CGPoint(x: 0, y: -size / 2))
            path.addLine(to: CGPoint(x: size / 2, y: size / 2))
            path.addLine(to: CGPoint(x: -size / 2, y: size / 2))
            path.closeSubpath()
            return path
        }
    }
}

private struct StaticCelebrationDots: View {
    let habitColor: Color

    @State private var visible = false

    private let positions: [CGPoint] = [
        CGPoint(x: 0.18, y: 0.22),
        CGPoint(x: 0.34, y: 0.16),
        CGPoint(x: 0.66, y: 0.18),
        CGPoint(x: 0.82, y: 0.27),
        CGPoint(x: 0.22, y: 0.72),
        CGPoint(x: 0.38, y: 0.82),
        CGPoint(x: 0.64, y: 0.78),
        CGPoint(x: 0.8, y: 0.68)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(Array(positions.enumerated()), id: \.offset) { index, point in
                    Circle()
                        .fill(color(for: index))
                        .frame(width: 10 + CGFloat(index % 3) * 4, height: 10 + CGFloat(index % 3) * 4)
                        .position(x: point.x * proxy.size.width, y: point.y * proxy.size.height)
                        .opacity(visible ? 0.72 : 0)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    visible = true
                }
            }
        }
    }

    private func color(for index: Int) -> Color {
        [habitColor, AppColor.accent, AppColor.success, AppColor.warning][index % 4]
    }
}

private struct SeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        state = 6364136223846793005 &* state &+ 1442695040888963407
        let value = Double(state >> 11) / Double(UInt64.max >> 11)
        return range.lowerBound + (range.upperBound - range.lowerBound) * value
    }
}
