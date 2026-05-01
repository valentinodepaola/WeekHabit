//
//  ButtonCategoryComponent.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 25/04/26.
//

import SwiftUI

struct ButtonCategoryComponent: View {
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    let categories: [HabitCategory] = HabitCategory.allCases
    @Binding var selectedCategory: HabitCategory
    
    var body: some View {
        LazyVGrid(columns: self.columns, spacing: 15) {
            ForEach(categories, id: \.self) { category in
                Button {
                    selectedCategory = category
                } label: {
                    HStack(spacing: 15) {
                        IconComponent(
                            icon: category.icon,
                            color: category.color
                        )
                        .padding(.leading, 6)
                        Text(category.title)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(Color.primary)
                        Spacer()
                    }
                    .padding(10)
                }
                .background(selectedCategory == category ? category.color.opacity(0.2) : AppColor.surface)
                .cornerRadius(12)
            }
        }
    }
}

#Preview {
    ButtonCategoryComponent(
        selectedCategory: .constant(.health)
    )
}
