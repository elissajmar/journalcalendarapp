//
//  Block.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/11/26.
//

import Foundation

enum Recurrence: String, CaseIterable, Identifiable {
    case never = "never"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .never: return "Never Repeats"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

struct Block: Identifiable {
    let id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    var title: String
    var recurrence: Recurrence
    var subBlocks: [SubBlock]
    var isPending: Bool = false
    var originalDate: Date
    var exceptions: [String]
    var recurrenceEnd: Date?

    init(
        id: UUID = UUID(),
        date: Date,
        startTime: Date,
        endTime: Date,
        title: String,
        recurrence: Recurrence = .never,
        subBlocks: [SubBlock] = [],
        originalDate: Date? = nil,
        exceptions: [String] = [],
        recurrenceEnd: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.title = title
        self.recurrence = recurrence
        self.subBlocks = subBlocks
        self.originalDate = originalDate ?? date
        self.exceptions = exceptions
        self.recurrenceEnd = recurrenceEnd
    }

    /// The text from the first journal sub-block, or empty string.
    var text: String {
        for subBlock in subBlocks {
            if case .journal(_, let text) = subBlock { return text }
        }
        return ""
    }

    /// Combined journal text from all journal sub-blocks.
    var journalText: String {
        subBlocks.compactMap { subBlock in
            if case .journal(_, let text) = subBlock { return text }
            return nil
        }.joined(separator: "\n\n")
    }

    /// Name of the first location sub-block, if any.
    var locationName: String? {
        for subBlock in subBlocks {
            if case .location(_, let name, _, _) = subBlock, !name.isEmpty {
                return name
            }
        }
        return nil
    }

    /// Total count of images across all image sub-blocks.
    var imageCount: Int {
        subBlocks.compactMap { subBlock in
            if case .images(_, let data) = subBlock { return data.count }
            return nil
        }.reduce(0, +)
    }
}
