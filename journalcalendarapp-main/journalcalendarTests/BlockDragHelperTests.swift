//
//  BlockDragHelperTests.swift
//  journalcalendarTests
//
//  Tests for the drag-to-reschedule snap logic. When a user drags
//  a block on the calendar, the helper converts raw pixel offsets
//  into 15-minute-snapped time increments. This rounding math has
//  subtle edge cases (e.g., does 7.5 minutes round up or down?).
//

import Testing
import Foundation
import CoreGraphics
@testable import journalcalendar

@Suite("BlockDragHelper — drag-to-reschedule snapping calculations")
struct BlockDragHelperTests {
    
    // With hourHeight=60, 1 pixel = 1 minute, which makes the math easy to verify.
    let helper = BlockDragHelper(hourHeight: 60)
    
    // MARK: - Snapped Offset
    // snappedOffset converts a raw pixel drag into a pixel offset that
    // aligns to the nearest 15-minute grid line.
    // Internal formula: minutesDelta = (drag / 60) * 60 = drag minutes,
    // then rounds to nearest 15, then converts back: (snapped / 60) * 60 = snapped pixels.
    
    /// Dragging exactly 15 pixels = 15 minutes — an exact 15-min boundary.
    /// Should snap to exactly 15 pixels (no rounding needed).
    @Test func snappedOffsetExact15Minutes() {
        let offset = helper.snappedOffset(from: 15.0)
        #expect(offset == 15.0)
    }
    
    /// Dragging 7 pixels = 7 minutes. 7/15 = 0.467, which rounds to 0.
    /// The block snaps back to its original position (0 pixels).
    @Test func snappedOffsetRoundsDown() {
        let offset = helper.snappedOffset(from: 7.0)
        #expect(offset == 0.0)
    }
    
    /// Dragging 8 pixels = 8 minutes. 8/15 = 0.533, which rounds to 1.
    /// The block snaps forward to the 15-minute mark (15 pixels).
    @Test func snappedOffsetRoundsUp() {
        let offset = helper.snappedOffset(from: 8.0)
        #expect(offset == 15.0)
    }
    
    /// Zero drag means zero offset — the block doesn't move at all.
    @Test func snappedOffsetZeroDrag() {
        let offset = helper.snappedOffset(from: 0.0)
        #expect(offset == 0.0)
    }
    
    // MARK: - Snapped Drop Y
    // snappedDropY = baseYOffset + snappedOffset. This positions the block
    // visually at its snapped location during the drag gesture.
    
    /// A block at Y=600 (10:00 AM) dragged 30px (30 min) should land at Y=630 (10:30 AM).
    @Test func snappedDropYCombinesBaseAndSnap() {
        let block = makeBlock(startHour: 10, endHour: 11)
        let y = helper.snappedDropY(for: block, dragOffset: 30.0, baseYOffset: 600.0)
        // snappedOffset(30) = 30 (exact 30-min snap), so 600 + 30 = 630
        #expect(y == 630.0)
    }
    
    // MARK: - Snapped Time Label
    // Formats the snapped new start time as a 24-hour string (HH:mm).
    // This label is shown to the user during the drag to indicate
    // where the block will land.
    
    /// A block starting at 10:00, dragged 30px (30 min) → label "10:30".
    @Test func snappedTimeLabelFormats24Hour() {
        let block = makeBlock(startHour: 10, endHour: 11)
        let label = helper.snappedTimeLabel(for: block, dragOffset: 30.0)
        #expect(label == "10:30")
    }
    
    // MARK: - New Times After Drag
    // newTimes() returns the final start/end times after a completed drag.
    // Returns nil if the snapped delta is zero (no meaningful change).
    // The block's duration must be preserved (end - start stays the same).
    
    /// A drag of 7px rounds to 0 minutes → no change → returns nil.
    /// This prevents unnecessary data updates for tiny accidental drags.
    @Test func newTimesReturnsNilForNoChange() {
        let block = makeBlock(startHour: 10, endHour: 11)
        let result = helper.newTimes(for: block, translation: 7.0)
        #expect(result == nil)
    }
    
    /// A 1-hour block (10:00-11:00) dragged 30px (30 min) should become 10:30-11:30.
    /// The duration must remain exactly 1 hour (3600 seconds).
    @Test func newTimesPreservesDuration() {
        let block = makeBlock(startHour: 10, endHour: 11)
        let result = helper.newTimes(for: block, translation: 30.0)
        
        // Should not be nil — 30 min is a real change
        #expect(result != nil)
        
        // Duration is preserved: still exactly 1 hour
        let duration = result!.end.timeIntervalSince(result!.start)
        #expect(duration == 3600)
        
        // New start should be 10:30
        let calendar = Calendar.current
        #expect(calendar.component(.hour, from: result!.start) == 10)
        #expect(calendar.component(.minute, from: result!.start) == 30)
    }
}
