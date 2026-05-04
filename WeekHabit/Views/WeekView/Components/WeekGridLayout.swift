//
//  WeekGridLayout.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 01/05/26.
//

import SwiftUI

enum WeekGridLayout {
    static let accentStripWidth: CGFloat = 4
    static let cellSpacing: CGFloat = 8
    static let cellSize: CGFloat = 34
}

struct WeekProgressBar: View {
    
    let progress: Double
    let habitColor: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColor.surfaceMuted)
                    .frame(height: 5)

                Capsule()
                    .fill(habitColor)
                    .frame(width: progressWidth(in: geo.size.width), height: 5)
                    .animation(.easeOut(duration: 0.32), value: progress)
            }
        }
        .frame(height: 5)
    }

    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard progress > 0 else { return 0 }
        return max(8, totalWidth * CGFloat(min(progress, 1)))
    }
}
