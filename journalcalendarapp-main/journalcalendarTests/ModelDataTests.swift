//
//  ModelDataTests.swift
//  journalcalendarTests
//
//  Tests for the ModelData CRUD operations (create, update, delete).
//  ModelData is the app's central data store. Its init() preloads
//  3 sample blocks, so tests account for that baseline.
//

import Testing
import Foundation
@testable import journalcalendar

@Suite("ModelData — CRUD operations on blocks")
struct ModelDataTests {
    
    // MARK: - Create
    
    /// Creating a block should increase the count by 1 and the new block
    /// should appear at the end of the array with the correct title.
    @Test func createBlockAddsToCollection() {
        let modelData = ModelData()
        let initialCount = modelData.blocks.count  // 3 from sample data
        
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let startTime = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date)!
        let endTime = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date)!
        
        modelData.createBlock(
            title: "New Block",
            startTime: startTime,
            endTime: endTime,
            subBlocks: []
        )
        
        #expect(modelData.blocks.count == initialCount + 1)
        #expect(modelData.blocks.last?.title == "New Block")
    }
    
    /// createBlock should normalize the date field to startOfDay of the startTime.
    /// This ensures blocks are grouped correctly by calendar day even if the
    /// startTime includes hours/minutes.
    @Test func createBlockNormalizesDate() {
        let modelData = ModelData()
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let startTime = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: date)!
        let endTime = calendar.date(bySettingHour: 15, minute: 30, second: 0, of: date)!
        
        modelData.createBlock(
            title: "Test",
            startTime: startTime,
            endTime: endTime,
            subBlocks: []
        )
        
        let createdBlock = modelData.blocks.last!
        let expectedDate = calendar.startOfDay(for: startTime)
        // The date should be midnight of that day, not the actual startTime
        #expect(createdBlock.date == expectedDate)
    }
    
    // MARK: - Update
    
    /// Updating a block by ID should change its title, times, and sub-blocks
    /// while keeping it at the same position in the array.
    @Test func updateBlockModifiesExistingBlock() {
        let modelData = ModelData()
        let blockId = modelData.blocks[0].id
        
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let newStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date)!
        let newEnd = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date)!
        
        modelData.updateBlock(
            id: blockId,
            title: "Updated Title",
            startTime: newStart,
            endTime: newEnd,
            subBlocks: [.journal(text: "Updated journal")]
        )
        
        let updated = modelData.blocks.first { $0.id == blockId }!
        #expect(updated.title == "Updated Title")
        #expect(updated.subBlocks.count == 1)
    }
    
    /// Calling updateBlock with a UUID that doesn't exist should silently
    /// do nothing — no crash, no data corruption. The block count stays the same.
    @Test func updateBlockIgnoresInvalidId() {
        let modelData = ModelData()
        let initialCount = modelData.blocks.count
        let fakeId = UUID()
        
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let time = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date)!
        
        modelData.updateBlock(
            id: fakeId,
            title: "Ghost",
            startTime: time,
            endTime: time,
            subBlocks: []
        )
        
        // Nothing should change
        #expect(modelData.blocks.count == initialCount)
    }
    
    // MARK: - Delete
    
    /// Deleting a block by ID should remove it from the array.
    /// The block should no longer be findable by its ID.
    @Test func deleteBlockRemovesById() {
        let modelData = ModelData()
        let initialCount = modelData.blocks.count
        let blockId = modelData.blocks[0].id
        
        modelData.deleteBlock(id: blockId)
        
        #expect(modelData.blocks.count == initialCount - 1)
        #expect(modelData.blocks.first(where: { $0.id == blockId }) == nil)
    }
}
