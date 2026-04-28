//
//  CategoryBadgeView.swift
//  WeekHabit
//

import SwiftUI

struct CategoryBadgeView: View {
    let category: HabitCategory

    var body: some View {
        HStack {
            Image(systemName: category.icon)
            Text(category.displayTitle.uppercased())
        }
        .font(AppFont.formSectionText2)
        .fontWeight(.semibold)
        .foregroundStyle(category.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(category.color.opacity(0.18))
        .clipShape(Capsule())
    }
}

#Preview {
    CategoryBadgeView(category: .health)
}
