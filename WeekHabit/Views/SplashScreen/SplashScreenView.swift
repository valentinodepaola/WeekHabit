//
//  SplashScreenView.swift
//  WeekHabit
//

import SwiftUI

struct SplashScreenView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showBars = Array(repeating: false, count: 7)
    @State private var checkProgress: CGFloat = 0
    @State private var checkScale: CGFloat = 0.85
    @State private var checkOpacity = 0.0
    @State private var didStartAnimation = false

    private let bars: [SplashBarConfiguration] = [
        SplashBarConfiguration(width: 176, color: Color(red: 0.76, green: 0.31, blue: 0.20), xOffset: 0, startXOffset: -26, startYOffset: 14, startRotation: -3),
        SplashBarConfiguration(width: 176, color: Color(red: 0.76, green: 0.31, blue: 0.20), xOffset: -8, startXOffset: 22, startYOffset: 12, startRotation: 2),
        SplashBarConfiguration(width: 176, color: Color(red: 0.88, green: 0.53, blue: 0.22), xOffset: 10, startXOffset: -18, startYOffset: 10, startRotation: -2),
        SplashBarConfiguration(width: 176, color: Color(red: 0.76, green: 0.31, blue: 0.20), xOffset: -5, startXOffset: 18, startYOffset: 8, startRotation: 1.6),
        SplashBarConfiguration(width: 176, color: Color(red: 0.88, green: 0.53, blue: 0.22), xOffset: 7, startXOffset: -14, startYOffset: 6, startRotation: -1.4),
        SplashBarConfiguration(width: 176, color: Color(red: 0.76, green: 0.31, blue: 0.20), xOffset: 0, startXOffset: 12, startYOffset: 5, startRotation: 1),
        SplashBarConfiguration(width: 196, color: Color(red: 0.09, green: 0.08, blue: 0.05), xOffset: 0, startXOffset: 0, startYOffset: 16, startRotation: 0)
    ]

    var body: some View {
        ZStack {
            AppBackground {
                VStack(spacing: 10) {
                    ForEach(bars.indices, id: \.self) { index in
                        let bar = bars[index]

                        SplashPillBarView(
                            width: bar.width,
                            color: bar.color
                        )
                        .scaleEffect(
                            x: showBars[index] ? 1 : 0.18,
                            y: showBars[index] ? 1 : 0.72,
                            anchor: .center
                        )
                        .rotationEffect(.degrees(showBars[index] ? 0 : bar.startRotation))
                        .opacity(showBars[index] ? 1 : 0)
                        .offset(
                            x: bar.xOffset + (showBars[index] ? 0 : bar.startXOffset),
                            y: showBars[index] ? 0 : bar.startYOffset
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                SplashCheckmarkShape()
                    .trim(from: 0, to: checkProgress)
                    .stroke(
                        Color.white,
                        style: StrokeStyle(
                            lineWidth: 14,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: 116, height: 88)
                    .scaleEffect(checkScale)
                    .opacity(checkOpacity)
                    .offset(y: 64)
                    .zIndex(1)
            }
        }
        .onAppear(perform: startAnimation)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("WeekHabit")
    }

    private func startAnimation() {
        guard !didStartAnimation else { return }
        didStartAnimation = true

        if reduceMotion {
            showBars = Array(repeating: true, count: bars.count)
            checkProgress = 1
            checkScale = 1
            checkOpacity = 1
            return
        }

        for index in showBars.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) {
                withAnimation(.spring(response: 0.48, dampingFraction: 0.62, blendDuration: 0.08)) {
                    showBars[index] = true
                }
            }
        }

        let checkDelay = Double(showBars.count) * 0.08 + 0.15

        DispatchQueue.main.asyncAfter(deadline: .now() + checkDelay) {
            withAnimation(.easeOut(duration: 0.08)) {
                checkOpacity = 1
            }

            withAnimation(.easeOut(duration: 0.28)) {
                checkProgress = 1
            }

            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                checkScale = 1
            }
        }
    }
}

private struct SplashBarConfiguration {
    let width: CGFloat
    let color: Color
    let xOffset: CGFloat
    let startXOffset: CGFloat
    let startYOffset: CGFloat
    let startRotation: Double
}

private struct SplashPillBarView: View {
    let width: CGFloat
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(0.85),
                        color,
                        color.opacity(0.75)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: width, height: 16)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 0.7)
            }
            .shadow(color: .black.opacity(0.26), radius: 5, x: 0, y: 3)
    }
}

private struct SplashCheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(
            to: CGPoint(
                x: rect.minX + rect.width * 0.18,
                y: rect.minY + rect.height * 0.52
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX + rect.width * 0.42,
                y: rect.minY + rect.height * 0.78
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX + rect.width * 0.86,
                y: rect.minY + rect.height * 0.22
            )
        )

        return path
    }
}

#Preview {
    SplashScreenView()
}
