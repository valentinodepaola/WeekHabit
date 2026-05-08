//
//  FocusDurationPicker.swift
//  WeekHabit
//

import SwiftUI

struct FocusDurationPicker: View {
    @Binding var selectedDuration: FocusDurationPreset

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            Text("DURACIÓN")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(0.8)

            HStack(spacing: AppSpacing.s) {
                ForEach(FocusDurationPreset.allCases) { duration in
                    Button {
                        selectedDuration = duration
                    } label: {
                        VStack(spacing: 2) {
                            Text(duration.title)
                                .font(AppFont.bodyEmphasis)
                            Text(duration.subtitle)
                                .font(AppFont.label)
                        }
                        .foregroundStyle(selectedDuration == duration ? .white : AppColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.m)
                        .background(selectedDuration == duration ? AppColor.accent : AppColor.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                                .strokeBorder(selectedDuration == duration ? Color.clear : AppColor.divider, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
