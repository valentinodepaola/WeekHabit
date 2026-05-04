//
//  HabitIconSearchField.swift
//  WeekHabit
//

import SwiftUI

struct HabitIconSearchField: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.subtleText)

            TextField("Buscar icono", text: $searchText)
                .font(AppFont.body2)
                .foregroundStyle(AppColor.strongText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }
}
