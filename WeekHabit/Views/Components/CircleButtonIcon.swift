//
//  CircleButtonIcon.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI

struct CircleButtonIcon: View {
    var icon: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20).bold())
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Color(hex: "#c2573c"))
                .clipShape(Circle())
        }
    }
}


#Preview {
    CircleButtonIcon(
        icon: "plus",
    ) {
        print("Pressed")
    }
}
