//
//  AppBackground.swift
//  WeekHabit
//
//  Fondo de pantalla coherente con el sistema. Usa `bgCanvas` adaptivo.
//

import SwiftUI

struct AppBackground<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppColor.bgCanvas
                .ignoresSafeArea()

            content
        }
        .whKeyboardDoneToolbar()
    }
}
