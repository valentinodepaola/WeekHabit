//
//  TextFieldComponent.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 24/04/26.
//

import SwiftUI

struct TextFieldComponent: View {
    
    var titleSection: String
    var placeholder: String
    @Binding var habitName: String
    var normalTextField: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(self.titleSection)
                .font(AppFont.formSectionText)
                .foregroundStyle(Color(hex: "#6b6458"))
                .textCase(.uppercase)
            
            if normalTextField {
                TextField(self.placeholder, text: $habitName)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            } else {
                TextField(self.placeholder, text: $habitName, axis: .vertical)
                    .lineLimit(5...10)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


#Preview {
    TextFieldComponent(
        titleSection: "Nombre",
        placeholder: "Ingresa el nombre del habito",
        habitName: .constant(""),
        normalTextField: true
    )
}
