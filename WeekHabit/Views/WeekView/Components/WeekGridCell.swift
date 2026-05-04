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
    let habitColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                shape

                if state == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: state)
                }

                if state == .partial {
                    Circle()
                        .fill(habitColor)
                        .frame(width: 8, height: 8)
                }

                if state == .inactive {
                    Text("-")
                        .font(AppFont.formSectionText2)
                        .foregroundStyle(AppColor.subtleText)
                }
            }
            .frame(width: WeekGridLayout.cellSize, height: WeekGridLayout.cellSize)
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
        }
        .buttonStyle(WeekGridCellButtonStyle())
        .disabled(state == .inactive || state == .future)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var shape: some View {
        switch state {
        case .completed:
            RoundedRectangle(cornerRadius: AppRadius.small)
                .fill(habitColor)
                .shadow(color: habitColor.opacity(0.24), radius: 7, x: 0, y: 4)
        case .partial:
            RoundedRectangle(cornerRadius: AppRadius.small)
                .fill(habitColor.opacity(0.18))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.small)
                        .stroke(habitColor.opacity(0.36), lineWidth: 1)
                }
        case .pending:
            RoundedRectangle(cornerRadius: AppRadius.small)
                .fill(habitColor.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.small)
                        .stroke(habitColor.opacity(0.24), lineWidth: 1)
                }
        case .inactive:
            RoundedRectangle(cornerRadius: AppRadius.small)
                .fill(AppColor.surface.opacity(0.62))
        case .future:
            RoundedRectangle(cornerRadius: AppRadius.small)
                .fill(AppColor.surface.opacity(0.28))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.small)
                        .stroke(AppColor.subtleText.opacity(0.14), lineWidth: 1)
                }
        }
    }
}

private struct WeekGridCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
