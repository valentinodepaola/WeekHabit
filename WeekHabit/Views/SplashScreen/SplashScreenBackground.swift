//
//  SplashScreenBackground.swift
//  WeekHabit
//

import SwiftUI

struct SplashScreenBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            baseBackgroundColor
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    AppColor.accent.opacity(colorScheme == .dark ? 0.18 : 0.13),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.clear,
                    AppColor.surface.opacity(colorScheme == .dark ? 0.08 : 0.34)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var baseBackgroundColor: Color {
        colorScheme == .dark ? AppColor.bgDark : AppColor.bgLight
    }
}

