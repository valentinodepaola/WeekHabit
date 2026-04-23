//
//  EmptyStateIcon.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI

struct EmptyStateIcon: View {
    
    // Personaliza con tus colores de tema
    var accentColor: Color = Color(hex: "#c2573c")
    var fillColor: Color = Color(hex: "#f3d9cf")
    
    var body: some View {
        ZStack {
            // Círculo exterior punteado
            Circle()
                .strokeBorder(style: StrokeStyle(
                    lineWidth: 2,
                    dash: [6, 5]
                ))
                .foregroundStyle(fillColor)
                .frame(width: 180, height: 180)
            
            // Círculo interior sólido
            Circle()
                .foregroundStyle(fillColor)
                .frame(width: 80, height: 80)
            
            // Ícono central
            Image(systemName: "circle.hexagongrid")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(accentColor)
        }
    }
}

#Preview {
    EmptyStateIcon()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.99, green: 0.96, blue: 0.94))
}
