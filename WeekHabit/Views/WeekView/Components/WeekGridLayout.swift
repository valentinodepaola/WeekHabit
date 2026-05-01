//
//  WeekGridLayout.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 01/05/26.
//

import SwiftUI

enum WeekGridLayout {
    static let categoryStripWidth: CGFloat = 4
    static let cellSpacing: CGFloat = 10
    static let cellSize: CGFloat = 38
}

struct WeekProgressBar: View {
    
    let progress: Double
    let categoryColor: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColor.bgLight)
                    .frame(height: 3)

                Capsule()
                    .fill(categoryColor.opacity(0.85))
                    .frame(width: max(6, geo.size.width * progress), height: 3)
                    .animation(.easeOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 3)
    }
}
