//
//  SplashPulseRing.swift
//  WeekHabit
//

import SwiftUI

struct SplashPulseRing: View {
    let index: Int
    let isExpanded: Bool
    let isVisible: Bool

    private var size: CGFloat {
        152 + CGFloat(index * 38)
    }

    private var opacity: Double {
        guard isVisible else { return 0 }
        return 0.19 - Double(index) * 0.045
    }

    var body: some View {
        Circle()
            .stroke(AppColor.accent, lineWidth: 1.2)
            .frame(width: size, height: size)
            .scaleEffect(isExpanded ? 1.05 + CGFloat(index) * 0.015 : 0.98)
            .opacity(opacity)
    }
}

