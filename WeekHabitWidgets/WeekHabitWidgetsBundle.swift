//
//  WeekHabitWidgetsBundle.swift
//  WeekHabitWidgets
//

import SwiftUI
import WidgetKit

@main
struct WeekHabitWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
        YearHeatmapWidget()
        FocusSessionLiveActivity()
    }
}
