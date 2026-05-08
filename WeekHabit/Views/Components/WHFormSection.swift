//
//  WHFormSection.swift
//  WeekHabit
//
//  Bloque de formulario: label en mayúsculas + control + helper opcional.
//  Reemplaza HabitBasicInfoSection y similares en CreateHabitView/CreatePlanView.
//

import SwiftUI

struct WHFormSection<Content: View>: View {
    var title: String? = nil
    var helper: String? = nil
    let content: Content

    init(
        title: String? = nil,
        helper: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.helper = helper
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            if let title {
                Text(title.uppercased())
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.6)
            }

            content

            if let helper {
                Text(helper)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
