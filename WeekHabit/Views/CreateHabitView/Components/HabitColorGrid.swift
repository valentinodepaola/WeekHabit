//
//  HabitColorGrid.swift
//  WeekHabit
//

import SwiftUI

struct HabitColorGrid: View {
    @Binding var selectedColorHex: String

    private let columns = [
        GridItem(.adaptive(minimum: 42), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(HabitAppearance.colorHexes, id: \.self) { colorHex in
                    HabitColorOptionButton(
                        colorHex: colorHex,
                        isSelected: selectedColorHex == colorHex
                    ) {
                        selectedColorHex = colorHex
                    }
                }
            }
            .padding(.top, 2)
            .padding(.bottom, 18)
        }
    }
}
