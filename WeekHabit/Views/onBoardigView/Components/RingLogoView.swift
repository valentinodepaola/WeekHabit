//
//  RingLogoView.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 24/04/26.
//
import SwiftUI

struct RippleLogoView: View {
    let rings = [1.0, 0.82, 0.65, 0.50, 0.37]
    let baseSize: CGFloat = 240

    var body: some View {
        VStack {
            ZStack {
                ForEach(rings.indices, id: \.self) { i in
                    Circle()
                        .stroke(Color(hex: "#c2573c"),
                                lineWidth: 1.5)
                        .frame(width: baseSize * rings[i],
                               height: baseSize * rings[i])
                        .opacity(Double(i + 1) * 0.14)
                }
                Circle()
                    .fill(Color(hex: "#c2573c"))
                    .frame(width: 68, height: 68)
                Image(systemName: "flame.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width: baseSize, height: baseSize)
        }
    }
}

#Preview {
    RippleLogoView()
}
