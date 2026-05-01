//
//  FocusDurationPicker.swift
//  WeekHabit
//

import SwiftUI

struct FocusDurationPicker: View {
    @Binding var selectedDuration: FocusDurationPreset

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DURACIÓN")
                .font(AppFont.formSectionText)
                .foregroundStyle(AppColor.mutedText)
                .tracking(1.3)

            HStack(spacing: 10) {
                ForEach(FocusDurationPreset.allCases) { duration in
                    Button {
                        selectedDuration = duration
                    } label: {
                        VStack(spacing: 2) {
                            Text(duration.title)
                                .font(AppFont.body2)
                                .fontWeight(.bold)

                            Text(duration.subtitle)
                                .font(AppFont.formSectionText2)
                        }
                        .foregroundStyle(selectedDuration == duration ? .white : AppColor.mutedText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedDuration == duration ? AppColor.accent : AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
