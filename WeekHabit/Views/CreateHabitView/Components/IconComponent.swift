//
//  IconComponent.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 25/04/26.
//
import SwiftUI

struct IconComponent: View {
    var icon: String
    var color: Color
    var body: some View {
        VStack {
            Image(systemName: self.icon)
                .foregroundStyle(self.color)
        }
        .frame(width: 8, height: 8)
        .padding()
        .background(self.color.opacity(0.2))
        .cornerRadius(12)
    }
}


#Preview {
    IconComponent(icon: "book", color: .blue)
}
