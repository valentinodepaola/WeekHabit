//
//  EmptyStateIcon.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI

struct EmptyStateIcon: View {
    
    // Personaliza con tus colores de tema
    var iconColor: Color
    var fillColor: Color
    var insideCirculeColor: Color
    let icon: String
    
    var body: some View {
        ZStack {
            // Círculo exterior punteado
            Circle()
                .strokeBorder(style: StrokeStyle(
                    lineWidth: 2,
                    dash: [6, 5]
                ))
                .foregroundStyle(self.fillColor)
                .frame(width: 180, height: 180)
            
            // Círculo interior sólido
            Circle()
                .foregroundStyle(self.insideCirculeColor)
                .frame(width: 80, height: 80)
            
            // Ícono central
            Image(systemName: self.icon)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(self.iconColor)
        }
    }
}

#Preview {
    EmptyStateIcon(
        iconColor: AppColor.accent,
        fillColor: AppColor.accentSoft,
        insideCirculeColor: AppColor.accentSoft,
        icon: "circle.hexagongrid"
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(red: 0.99, green: 0.96, blue: 0.94))
}
