//
//  DateFormattersTests.swift
//  journalcalendarTests
//
//  Tests for the date/time formatting utilities. These formatters
//  are used throughout the UI for hour labels on the calendar grid,
//  time ranges on event blocks, and date headers. The hourLabel
//  function has branching logic for midnight (0→"12AM") and noon
//  (12→"12PM") that's easy to get wrong.
//

import Testing
import Foundation
@testable import journalcalendar

@Suite("DateFormatters — time and date label formatting")
struct DateFormattersTests {
    
    // MARK: - Hour Labels
    // hourLabel converts a 24-hour integer (0-23) to a compact AM/PM string.
    // Special cases: 0 → "12AM" (midnight), 12 → "12PM" (noon).
    // The rest follow the pattern: 1-11 → "1AM"-"11AM", 13-23 → "1PM"-"11PM".
    
    /// Test the morning hours including the tricky midnight case.
    /// Hour 0 is midnight which displays as "12AM" (not "0AM").
    @Test func hourLabelMorningHours() {
        #expect(DateFormatters.hourLabel(for: 0) == "12AM")   // midnight
        #expect(DateFormatters.hourLabel(for: 1) == "1AM")
        #expect(DateFormatters.hourLabel(for: 6) == "6AM")
        #expect(DateFormatters.hourLabel(for: 11) == "11AM")
    }
    
    /// Test the afternoon hours including the tricky noon case.
    /// Hour 12 is noon which displays as "12PM" (not "0PM").
    @Test func hourLabelAfternoonHours() {
        #expect(DateFormatters.hourLabel(for: 12) == "12PM")  // noon
        #expect(DateFormatters.hourLabel(for: 13) == "1PM")
        #expect(DateFormatters.hourLabel(for: 18) == "6PM")
        #expect(DateFormatters.hourLabel(for: 23) == "11PM")
    }
    
    // MARK: - Time Range
    // timeRange formats two Date values into "10:00AM - 11:00AM" style.
    // It uses the time12h formatter (h:mma) with .uppercased().
    
    /// A simple same-period range: 10:00 AM to 11:00 AM.
    @Test func timeRangeFormatting() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let start = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date)!
        let end = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: date)!
        
        let result = DateFormatters.timeRange(from: start, to: end)
        #expect(result == "10:00AM - 11:00AM")
    }
    
    /// A range that crosses noon: 11:00 AM to 1:00 PM.
    /// Both the AM and PM suffixes should be correct.
    @Test func timeRangeCrossingNoon() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let start = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: date)!
        let end = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: date)!
        
        let result = DateFormatters.timeRange(from: start, to: end)
        #expect(result == "11:00AM - 1:00PM")
    }
    
    // MARK: - Short Date
    // shortDate formats a Date as "EEE, MMM d" (e.g., "Thu, Jan 15").
    
    /// January 15, 2026 is a Thursday → "Thu, Jan 15".
    @Test func shortDateFormatting() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        
        let result = DateFormatters.shortDate(from: date)
        #expect(result == "Thu, Jan 15")
    }
}
