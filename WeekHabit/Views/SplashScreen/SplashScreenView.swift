//
//  SplashScreenView.swift
//  WeekHabit
//

import SwiftUI

struct SplashScreenView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var animationState = SplashScreenAnimationState()

    var body: some View {
        ZStack {
            SplashScreenBackground()

            VStack(spacing: 30) {
                Spacer(minLength: 40)

                SplashRhythmMark(
                    progress: animationState.ringProgress,
                    pulseIsExpanded: animationState.pulseIsExpanded,
                    contentIsVisible: animationState.contentIsVisible
                )
                .scaleEffect(animationState.contentIsVisible ? 1 : 0.92)
                .opacity(animationState.contentIsVisible ? 1 : 0)

                SplashBrandLockup()
                    .offset(y: animationState.contentIsVisible ? 0 : 10)
                    .opacity(animationState.contentIsVisible ? 1 : 0)

                SplashWeekStrip(progress: animationState.ringProgress)
                    .padding(.top, 4)
                    .opacity(animationState.contentIsVisible ? 1 : 0)

                Spacer(minLength: 56)

                SplashLoadingLabel()
                    .opacity(animationState.contentIsVisible ? 1 : 0)
            }
            .padding(.horizontal, 28)
        }
        .onAppear(perform: startAnimation)
    }

    private func startAnimation() {
        guard animationState.markAppeared() else { return }

        if reduceMotion {
            animationState.applyReducedMotion()
            return
        }

        withAnimation(SplashScreenMotion.reveal) {
            animationState.revealContent()
        }

        withAnimation(SplashScreenMotion.progress) {
            animationState.completeRing()
        }

        withAnimation(SplashScreenMotion.pulse) {
            animationState.expandPulse()
        }
    }
}

#Preview {
    SplashScreenView()
}
