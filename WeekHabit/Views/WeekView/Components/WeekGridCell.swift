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
        case partial
        case pending
        case inactive
        case future
    }

    let state: State
    let categoryColor: Color
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

                if state == .partial {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 7, height: 7)
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
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var shape: some View {
        switch state {
        case .completed:
            RoundedRectangle(cornerRadius: AppRadius.small)
                .fill(categoryColor)
        case .partial:
            RoundedRectangle(cornerRadius: AppRadius.small)
                .fill(categoryColor.opacity(0.18))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.small)
                        .stroke(categoryColor.opacity(0.36), lineWidth: 1)
                }
        case .pending:
            RoundedRectangle(cornerRadius: AppRadius.small)
                .fill(categoryColor.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.small)
                        .stroke(categoryColor.opacity(0.24), lineWidth: 1)
                }
        case .inactive:
            RoundedRectangle(cornerRadius: AppRadius.small)
                .fill(AppColor.bgLight.opacity(0.7))
        case .future:
            RoundedRectangle(cornerRadius: AppRadius.small)
                .stroke(AppColor.subtleText.opacity(0.16), lineWidth: 1)
                .opacity(0.5)
        }
    }
}
