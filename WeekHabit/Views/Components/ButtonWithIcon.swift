//
//  ButtonWithIcon.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI

struct ButtonWithIcon: View {
    var icon: String? = nil
    var text: String
    var action: () -> Void
    
    var body: some View {
        Button {
            self.action()
        } label: {
            HStack {
                if let icon = self.icon {
                    Image(systemName: self.icon ?? "")
                }
                Text(self.text)
            }
            .fontWeight(.bold)
            .frame(width: 270, height: 50)
        }
        .background(Color(hex: "#c2573c"))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }
}

#Preview {
    ButtonWithIcon(
        icon: "plus",
        text: "Crear mi primer habito"
    ) {
        print("pressed")
    }
}
