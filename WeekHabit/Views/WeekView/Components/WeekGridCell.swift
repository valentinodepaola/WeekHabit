//
//  WeekGridCell.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 01/05/26.
//

import SwiftUI

struct WeekGridCell: View {
    enum State: Equatable {
        case completed
        case pending
        case inactive
        case future
    }

    let state: State
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                shape

                if state == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }

                if state == .inactive {
                    Text("-")
                        .font(AppFont.formSectionText2)
                        .foregroundStyle(AppColor.subtleText)
                }
            }
            .frame(width: WeekGridLayout.cellSize, height: WeekGridLayout.cellSize)
        }
        .buttonStyle(.plain)
        .disabled(state == .inactive || state == .future)
    }

    @ViewBuilder
    private var shape: some View {
        switch state {
        case .completed:
            RoundedRectangle(cornerRadius: AppRadius.small)
                .fill(AppColor.accent)
        case .pending:
            RoundedRectangle(cornerRadius: AppRadius.small)
                .fill(AppColor.accentSoft.opacity(0.55))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.small)
                        .stroke(AppColor.accent.opacity(0.20), lineWidth: 1)
                }
        case .inactive:
            RoundedRectangle(cornerRadius: AppRadius.small)
                .fill(AppColor.surfaceMuted)
        case .future:
            RoundedRectangle(cornerRadius: AppRadius.small)
                .stroke(AppColor.subtleText.opacity(0.2), lineWidth: 1)
                .opacity(0.5)
        }
    }
}
