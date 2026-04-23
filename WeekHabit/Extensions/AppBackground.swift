//
//  AppBackground.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//
import SwiftUI

struct AppBackground<Content: View> : View {
    @Environment(\.colorScheme) private var colorScheme
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            self.content
        }
    }
    
    private var backgroundColor: Color {
        switch colorScheme {
        case .dark:
            Color(hex: "#121010")
            
        default:
            Color(hex: "#f5f1ea")
        }
    }
}
