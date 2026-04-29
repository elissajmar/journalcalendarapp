//
//  BlockLayoutEngineTests.swift
//  journalcalendarTests
//
//  Tests for the calendar grid layout engine — the most complex
//  algorithm in the app. It handles overlap detection between blocks,
//  column assignment for side-by-side display, and pixel math for
//  converting times to heights and Y positions.
//

import Testing
import Foundation
import CoreGraphics
@testable import journalcalendar

@Suite("BlockLayoutEngine — calendar grid layout calculations")
struct BlockLayoutEngineTests {
    
    // Default engine: 60 points per hour (1pt = 1min)
    let engine = BlockLayoutEngine(hourHeight: 60)
    
    // MARK: - Height Calculation
    // The formula is: max(hours * hourHeight - 8, 16)
    // The -8 accounts for visual padding between blocks,
    // and 16 is the minimum height so tiny blocks stay tappable.
    
    /// A 1-hour block: (1.0 * 60) - 8 = 52 points.
    @Test func heightForOneHourBlock() {
        let block = makeBlock(startHour: 10, endHour: 11)
        let h = engine.height(for: block)
        #expect(h == 52)
    }
    
    /// A 30-minute block: (0.5 * 60) - 8 = 22 points.
    @Test func heightForThirtyMinuteBlock() {
        let block = makeBlock(startHour: 10, endHour: 10, endMinute: 30)
        let h = engine.height(for: block)
        #expect(h == 22)
    }
    
    /// A very short 5-minute block would compute (5/60 * 60) - 8 = -3,
    /// but the min-height clamp catches it and returns 16.
    @Test func heightClampsToMinimum() {
        let block = makeBlock(startHour: 10, endHour: 10, endMinute: 5)
        let h = engine.height(for: block)
        #expect(h == 16)
    }
    
    // MARK: - Y Offset Calculation
    // The formula is: hour * hourHeight + (minute / 60) * hourHeight
    // With hourHeight=60, this simplifies to: hour * 60 + minute.
    
    /// Test Y offset at midnight (0), 10:00 AM (600), and 10:30 AM (630).
    /// These three values cover the start of day, a typical morning time,
    /// and a fractional-hour offset.
    @Test func yOffsetAtVariousTimes() {
        // Midnight: 0 * 60 + 0 = 0
        let midnight = makeBlock(startHour: 0, endHour: 1)
        #expect(engine.yOffset(for: midnight) == 0)
        
        // 10:00 AM: 10 * 60 + 0 = 600
        let tenAM = makeBlock(startHour: 10, endHour: 11)
        #expect(engine.yOffset(for: tenAM) == 600)
        
        // 10:30 AM: 10 * 60 + 30 = 630
        let tenThirty = makeBlock(startHour: 10, startMinute: 30, endHour: 11)
        #expect(engine.yOffset(for: tenThirty) == 630)
    }
    
    // MARK: - Overlap Detection
    // Two blocks overlap when: block1.start < block2.end AND block1.end > block2.start
    // This uses strict inequality, so blocks that merely touch (end == start) do NOT overlap.
    
    /// 10:00-11:00 and 10:30-11:30 share the 10:30-11:00 window → overlap.
    @Test func overlappingBlocksDetected() {
        let a = makeBlock(title: "A", startHour: 10, endHour: 11)
        let b = makeBlock(title: "B", startHour: 10, startMinute: 30, endHour: 11, endMinute: 30)
        #expect(engine.blocksOverlap(a, b) == true)
    }
    
    /// 10:00-11:00 and 11:00-12:00 are adjacent — they share the 11:00 boundary
    /// but do NOT overlap because the comparison uses strict < (not <=).
    @Test func adjacentBlocksDoNotOverlap() {
        let a = makeBlock(title: "A", startHour: 10, endHour: 11)
        let b = makeBlock(title: "B", startHour: 11, endHour: 12)
        #expect(engine.blocksOverlap(a, b) == false)
    }
    
    /// Two blocks far apart (9-10 and 14-15) clearly don't overlap.
    @Test func nonOverlappingBlocksDetected() {
        let a = makeBlock(title: "A", startHour: 9, endHour: 10)
        let b = makeBlock(title: "B", startHour: 14, endHour: 15)
        #expect(engine.blocksOverlap(a, b) == false)
    }
    
    // MARK: - Column Position Assignment
    // When blocks overlap, they get placed in separate columns (0, 1, 2, ...)
    // so they display side-by-side. The normalization pass ensures all blocks
    // in an overlap group share the same totalColumns value.
    
    /// Two overlapping blocks should get columns 0 and 1, each knowing
    /// there are 2 total columns so they split the available width.
    @Test func twoOverlappingBlocksGetSeparateColumns() {
        let a = makeBlock(title: "A", startHour: 10, endHour: 11)
        let b = makeBlock(title: "B", startHour: 10, startMinute: 30, endHour: 11, endMinute: 30)
        let positions = engine.positions(for: [a, b])
        
        #expect(positions.count == 2)
        
        // Find positions by block ID (positions are sorted by startTime)
        let posA = positions.first { $0.block.id == a.id }!
        let posB = positions.first { $0.block.id == b.id }!
        
        // A starts earlier so gets column 0; B gets column 1
        #expect(posA.column == 0)
        #expect(posB.column == 1)
        // Both see totalColumns = 2
        #expect(posA.totalColumns == 2)
        #expect(posB.totalColumns == 2)
    }
    
    /// Three blocks in a chain: A overlaps B, B overlaps C, but A does NOT overlap C.
    /// A: 10:00-11:00, B: 10:30-11:30, C: 11:15-12:00
    /// The normalization pass should propagate the max totalColumns across the group.
    @Test func threeChainOverlappingBlocks() {
        let a = makeBlock(title: "A", startHour: 10, endHour: 11)
        let b = makeBlock(title: "B", startHour: 10, startMinute: 30, endHour: 11, endMinute: 30)
        let c = makeBlock(title: "C", startHour: 11, startMinute: 15, endHour: 12)
        
        let positions = engine.positions(for: [a, b, c])
        #expect(positions.count == 3)
        
        let posA = positions.first { $0.block.id == a.id }!
        let posB = positions.first { $0.block.id == b.id }!
        let posC = positions.first { $0.block.id == c.id }!
        
        // A gets column 0, B gets column 1 (overlaps A)
        #expect(posA.column == 0)
        #expect(posB.column == 1)
        // C doesn't overlap A, so it can reuse column 0
        #expect(posC.column == 0)
    }
    
    /// Edge cases: an empty array returns no positions,
    /// and a single block gets column 0 with totalColumns 1.
    @Test func emptyAndSingleBlockPositions() {
        // Empty input
        let emptyPositions = engine.positions(for: [])
        #expect(emptyPositions.isEmpty)
        
        // Single block — no overlaps, so column 0, total 1
        let block = makeBlock(startHour: 10, endHour: 11)
        let positions = engine.positions(for: [block])
        #expect(positions.count == 1)
        #expect(positions[0].column == 0)
        #expect(positions[0].totalColumns == 1)
    }
}
