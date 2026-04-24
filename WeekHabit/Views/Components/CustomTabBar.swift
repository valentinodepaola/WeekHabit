//
//  CustomTabBar.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs: [TabItems] = [.today, .habits, .week, .insights]
    
    var body: some View {
        VStack {
            Divider()
            HStack {
                ForEach(tabs.indices, id: \.self) { index in
                    TabBarItem(
                        icon: tabs[index].icon,
                        text: tabs[index].description,
                        isSelected: selectedTab == index
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = index
                        }
                    }
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
        }
    }
}

enum TabItems: String {
    case today
    case habits
    case week
    case insights
    
    var description: String {
        switch self {
        case .today:
            return "Hoy"
        case .habits:
            return "Habitos"
        case .week:
            return "Semana"
        case .insights:
            return "Insights"
        }
    }
    
    var icon: String {
        switch self {
        case .today:
            return "sun.max"
        case .habits:
            return "list.bullet"
        case .week:
            return "calendar"
        case .insights:
            return "align.vertical.bottom.fill"
        }
    }
}

#Preview {
    CustomTabBar(selectedTab: .constant(0))
}
