//
//  DateFormatters.swift
//  journalcalendar
//
//  Reusable date/time formatting utilities.
//

import Foundation

enum DateFormatters {
    
    // MARK: - Cached Formatters
    
    /// 24-hour time, e.g. "14:30"
    static let time24h: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
    
    /// 12-hour time with AM/PM, e.g. "2:30PM"
    static let time12h: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mma"
        return f
    }()
    
    /// Short day + month, e.g. "Tue, Mar 10"
    static let shortDayMonth: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()
    
    // MARK: - Hour Labels
    
    /// Format an hour (0-23) as a label, e.g. "8AM", "12PM"
    static func hourLabel(for hour: Int) -> String {
        if hour == 0 {
            return "12AM"
        } else if hour < 12 {
            return "\(hour)AM"
        } else if hour == 12 {
            return "12PM"
        } else {
            return "\(hour - 12)PM"
        }
    }
    
    // MARK: - Time Range
    
    /// Format a start–end time range, e.g. "10:00AM - 11:00AM"
    static func timeRange(from start: Date, to end: Date) -> String {
        let s = time12h.string(from: start).uppercased()
        let e = time12h.string(from: end).uppercased()
        return "\(s) - \(e)"
    }
    
    // MARK: - Day Strings
    
    /// Short date string, e.g. "Tue, Mar 10"
    static func shortDate(from date: Date) -> String {
        shortDayMonth.string(from: date)
    }
}
