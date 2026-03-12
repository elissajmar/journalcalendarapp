//
//  JournalBlock.swift
//  Calendar Journal
//
//  Created on 3/11/26.
//

import Foundation
import SwiftData

@Model
final class JournalBlock {
    var id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var createdDate: Date
    var modifiedDate: Date
    
    @Relationship(deleteRule: .cascade, inverse: \SubBlock.journalBlock)
    var subBlocks: [SubBlock]
    
    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date,
        createdDate: Date = Date(),
        modifiedDate: Date = Date(),
        subBlocks: [SubBlock] = []
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.subBlocks = subBlocks
    }
    
    // MARK: - Computed Properties
    
    /// Duration of the block in hours
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    /// Formatted time range string (e.g., "11:00 AM - 1:00 PM")
    var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        return "\(start) - \(end)"
    }
    
    /// Total word count across all text sub-blocks
    var totalWordCount: Int {
        subBlocks.compactMap { $0 as? TextSubBlock }
            .reduce(0) { $0 + $1.wordCount }
    }
    
    /// Total image count across all image sub-blocks
    var totalImageCount: Int {
        subBlocks.compactMap { $0 as? ImagesSubBlock }
            .reduce(0) { $0 + $1.images.count }
    }
    
    // MARK: - Helper Methods
    
    /// Add a sub-block to this journal block
    func addSubBlock(_ subBlock: SubBlock) {
        subBlock.order = subBlocks.count
        subBlocks.append(subBlock)
        modifiedDate = Date()
    }
    
    /// Remove a sub-block from this journal block
    func removeSubBlock(_ subBlock: SubBlock) {
        if let index = subBlocks.firstIndex(where: { $0.id == subBlock.id }) {
            subBlocks.remove(at: index)
            // Reorder remaining sub-blocks
            for (newIndex, block) in subBlocks.enumerated() {
                block.order = newIndex
            }
            modifiedDate = Date()
        }
    }
    
    /// Update the modified date (call when editing)
    func markAsModified() {
        modifiedDate = Date()
    }
}

// MARK: - Sample Data

extension JournalBlock {
    /// Creates a sample lunch block for testing/preview
    static func sampleLunchBlock() -> JournalBlock {
        let calendar = Calendar.current
        let today = Date()
        
        // Create lunch time: 11 AM today
        let startDate = calendar.date(
            bySettingHour: 11,
            minute: 0,
            second: 0,
            of: today
        ) ?? today
        
        // End time: 1 PM today
        let endDate = calendar.date(
            bySettingHour: 13,
            minute: 0,
            second: 0,
            of: today
        ) ?? today
        
        let lunchBlock = JournalBlock(
            title: "Lunch",
            startDate: startDate,
            endDate: endDate
        )
        
        // Add text sub-block
        let textBlock = TextSubBlock(
            content: """
            Had a wonderful lunch at the new café downtown. The atmosphere was cozy and inviting, with \
            warm lighting and comfortable seating. I ordered the avocado toast with poached eggs and a \
            side of fresh fruit. The presentation was beautiful, and the taste exceeded my expectations.
            
            Met up with Sarah and we caught up on recent events. She shared exciting news about her new \
            job opportunity, and we discussed potential weekend plans. The conversation flowed naturally, \
            and it was great to reconnect after a few busy weeks.
            
            The café had this amazing house-made lemonade that was perfectly balanced - not too sweet, \
            with just the right amount of tartness. I'll definitely be coming back here again. The staff \
            was friendly and attentive without being intrusive.
            
            Overall, it was a refreshing break in the middle of the day. Sometimes it's the simple moments \
            like these that make you appreciate the little things in life. Good food, good company, and a \
            peaceful environment - what more could you ask for?
            """
        )
        lunchBlock.addSubBlock(textBlock)
        
        // Add images sub-block (we'll add placeholder data)
        let imagesBlock = ImagesSubBlock()
        // In a real app, we'd add actual image data here
        // For now, we'll leave it empty or add sample data in the ImagesSubBlock extension
        lunchBlock.addSubBlock(imagesBlock)
        
        return lunchBlock
    }
    
    /// Creates multiple sample blocks for a day
    static func sampleDayBlocks() -> [JournalBlock] {
        let calendar = Calendar.current
        let today = Date()
        
        var blocks: [JournalBlock] = []
        
        // Morning coffee - 9 AM
        let morningStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? today
        let morningEnd = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: today) ?? today
        let morningBlock = JournalBlock(
            title: "Morning Coffee",
            startDate: morningStart,
            endDate: morningEnd
        )
        let morningText = TextSubBlock(content: "Started the day with a strong espresso. Feeling energized and ready to tackle the day ahead!")
        morningBlock.addSubBlock(morningText)
        blocks.append(morningBlock)
        
        // Lunch - 11 AM
        blocks.append(sampleLunchBlock())
        
        // Team Meeting - 3 PM
        let meetingStart = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today) ?? today
        let meetingEnd = calendar.date(bySettingHour: 16, minute: 30, second: 0, of: today) ?? today
        let meetingBlock = JournalBlock(
            title: "Team Sync",
            startDate: meetingStart,
            endDate: meetingEnd
        )
        let meetingText = TextSubBlock(content: "Productive team meeting. Discussed Q2 goals and upcoming project deadlines. Everyone seems aligned on priorities.")
        meetingBlock.addSubBlock(meetingText)
        blocks.append(meetingBlock)
        
        // Dinner - 7 PM
        let dinnerStart = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today) ?? today
        let dinnerEnd = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today) ?? today
        let dinnerBlock = JournalBlock(
            title: "Dinner",
            startDate: dinnerStart,
            endDate: dinnerEnd
        )
        let dinnerText = TextSubBlock(content: "Homemade pasta tonight. Tried a new recipe for carbonara and it turned out great!")
        dinnerBlock.addSubBlock(dinnerText)
        blocks.append(dinnerBlock)
        
        return blocks
    }
}
