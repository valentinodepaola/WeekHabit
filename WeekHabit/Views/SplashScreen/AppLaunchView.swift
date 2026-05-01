//
//  AppLaunchView.swift
//  WeekHabit
//

import SwiftUI

struct AppLaunchView<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var phase: AppLaunchPhase = .splash
    @State private var didScheduleLaunch = false

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            content
                .opacity(phase == .splash ? 0 : 1)
                .scaleEffect(phase == .splash && !reduceMotion ? 1.015 : 1)
                .animation(AppLaunchTiming.contentAnimation(reduceMotion: reduceMotion), value: phase)
                .allowsHitTesting(phase == .complete)

            if phase != .complete {
                SplashScreenView()
                    .opacity(phase == .releasing ? 0 : 1)
                    .scaleEffect(phase == .releasing && !reduceMotion ? 1.04 : 1)
                    .blur(radius: phase == .releasing && !reduceMotion ? 8 : 0)
                    .animation(AppLaunchTiming.splashExitAnimation(reduceMotion: reduceMotion), value: phase)
                    .zIndex(1)
            }
        }
        .task {
            await runLaunchSequenceIfNeeded()
        }
    }

    @MainActor
    private func runLaunchSequenceIfNeeded() async {
        guard !didScheduleLaunch else { return }
        didScheduleLaunch = true

        let shouldReduceMotion = reduceMotion
        let holdDuration = AppLaunchTiming.holdDuration(reduceMotion: shouldReduceMotion)
        let releaseDuration = AppLaunchTiming.releaseDuration(reduceMotion: shouldReduceMotion)

        try? await Task.sleep(nanoseconds: holdDuration)

        withAnimation(AppLaunchTiming.splashExitAnimation(reduceMotion: shouldReduceMotion)) {
            phase = .releasing
        }

        try? await Task.sleep(nanoseconds: releaseDuration)

        withAnimation(AppLaunchTiming.contentAnimation(reduceMotion: shouldReduceMotion)) {
            phase = .complete
        }
    }
}
