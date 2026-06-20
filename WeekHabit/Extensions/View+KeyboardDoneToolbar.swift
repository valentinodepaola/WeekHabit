//
//  View+KeyboardDoneToolbar.swift
//  WeekHabit
//

import SwiftUI
import UIKit

extension View {
    func whKeyboardDoneToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Listo") {
                    KeyboardDismissal.dismiss()
                }
                .font(AppFont.bodyEmphasis)
                .tint(AppColor.accent)
            }
        }
    }
}

private enum KeyboardDismissal {
    @MainActor
    static func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
