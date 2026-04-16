//
//  DayNavigator.swift
//  journalcalendar
//
//  Manages selected date and day-switching animation state.
//

import SwiftUI

@Observable
final class DayNavigator {
    var selectedDate = Date()
    private(set) var swipeDirection = 1  // 1 = forward, -1 = backward

    var slideTransition: AnyTransition {
        swipeDirection > 0
            ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
            : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
    }

    func goToPreviousDay() {
        swipeDirection = -1
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        }
    }

    func goToNextDay() {
        swipeDirection = 1
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        }
    }
}
