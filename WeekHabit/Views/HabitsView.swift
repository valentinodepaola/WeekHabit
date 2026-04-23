//
//  HabitsView.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI
import SwiftData

struct HabitsView: View {
    var emptyState: Bool = true
    var body: some View {
        AppBackground {
            VStack() {
                HStack {
                    Text("Hábitos")
                        .font(AppFont.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    CircleButtonIcon(
                        icon: "plus"
                    ) {
                        //action
                    }
                }
                .padding(.horizontal)
                Spacer()
                
                if self.emptyState {
                    EmptyStateView()
                }
                
                Spacer()
                
            }
        }
    }
}

#Preview {
    HabitsView()
}

