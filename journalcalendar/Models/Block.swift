//
//  Block.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/11/26.
//

import Foundation

struct Block: Identifiable {
    let id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    var title: String
    var subBlocks: [SubBlock]
    var isPending: Bool = false

    init(
        id: UUID = UUID(),
        date: Date,
        startTime: Date,
        endTime: Date,
        title: String,
        subBlocks: [SubBlock] = []
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.title = title
        self.subBlocks = subBlocks
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
