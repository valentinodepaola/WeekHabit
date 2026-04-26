//
//  TabBarItem.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI

struct TabBarItem: View {
    
    var icon: String
    var text: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: self.action) {
            VStack(spacing: 5) {
                Image(systemName: self.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? AppColor.accent : .gray)
                    .frame(maxWidth: .infinity)
                Text(self.text)
                    .font(AppFont.tabBarText)
                    .foregroundStyle(isSelected ? AppColor.accent : .gray)
            }
        }
        .accessibilityLabel(self.text)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    TabBarItem(
        icon: "calendar",
        text: "Semana",
        isSelected: true
    ){
        
    }
}
