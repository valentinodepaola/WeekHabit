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
                .foregroundStyle(AppColor.mutedText)
                .textCase(.uppercase)
            
            if normalTextField {
                TextField(self.placeholder, text: $habitName)
                    .padding()
                    .background(AppColor.surface)
                    .cornerRadius(AppRadius.medium)
            } else {
                TextField(self.placeholder, text: $habitName, axis: .vertical)
                    .lineLimit(5...10)
                    .padding()
                    .background(AppColor.surface)
                    .cornerRadius(AppRadius.medium)
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
