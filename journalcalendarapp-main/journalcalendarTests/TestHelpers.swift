//
//  TestHelpers.swift
//  journalcalendarTests
//
//  Shared test utilities for creating Block instances with specific times.
//

import Foundation
@testable import journalcalendar

/// Creates a Block with times set to specific hours/minutes on a fixed reference date.
/// Uses January 15, 2026 — a date with no DST transitions — so tests are deterministic.
func makeBlock(
    title: String = "Test Block",
    startHour: Int,
    startMinute: Int = 0,
    endHour: Int,
    endMinute: Int = 0,
    subBlocks: [SubBlock] = []
) -> Block {
    let calendar = Calendar.current
    // Fixed reference date avoids DST and timezone edge cases
    let components = DateComponents(year: 2026, month: 1, day: 15)
    let referenceDate = calendar.date(from: components)!
    
    let startTime = calendar.date(
        bySettingHour: startHour, minute: startMinute, second: 0, of: referenceDate
    )!
    let endTime = calendar.date(
        bySettingHour: endHour, minute: endMinute, second: 0, of: referenceDate
    )!
    
    return Block(
        date: referenceDate,
        startTime: startTime,
        endTime: endTime,
        title: title,
        subBlocks: subBlocks
    )
}
