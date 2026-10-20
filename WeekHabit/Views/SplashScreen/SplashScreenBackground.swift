//
//  SplashScreenBackground.swift
//  WeekHabit
//

import SwiftUI

struct SplashScreenBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppColor.bgCanvas
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    AppColor.accent.opacity(colorScheme == .dark ? 0.16 : 0.12),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.clear,
                    AppColor.bgElevated.opacity(colorScheme == .dark ? 0.08 : 0.3)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

#Preview("Light") {
    SplashScreenBackground()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SplashScreenBackground()
        .preferredColorScheme(.dark)
}
