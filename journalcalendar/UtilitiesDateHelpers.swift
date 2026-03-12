//
//  DateHelpers.swift
//  Calendar Journal
//
//  Created on 3/11/26.
//

import Foundation

extension Date {
    /// Get the start of the day (midnight) for this date
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// Get the end of the day (11:59:59 PM) for this date
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    /// Check if this date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if this date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// Check if this date is tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    /// Get the previous day
    var previousDay: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: self) ?? self
    }
    
    /// Get the next day
    var nextDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: self) ?? self
    }
    
    /// Format date as "Tues, Mar 10" (day of week, month, day)
    var formattedDayHeader: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: self)
    }
    
    /// Format date as "March 10, 2026" (full date)
    var formattedLongDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: self)
    }
    
    /// Format time as "11:00 AM"
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
    
    /// Get hour component (0-23)
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }
    
    /// Get minute component (0-59)
    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }
    
    /// Create a date with a specific hour and minute on the same day
    func settingTime(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: self) ?? self
    }
}

extension Calendar {
    /// Get all hours in a day (0-23) as an array
    static var hoursInDay: [Int] {
        Array(0..<24)
    }
    
    /// Format hour as string (e.g., "9 AM", "12 PM", "3 PM")
    static func formatHour(_ hour: Int) -> String {
        let calendar = Calendar.current
        let today = Date()
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: today) ?? today
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }
}
