//
//  OffscreenBlockCounterTests.swift
//  journalcalendarTests
//
//  Tests for the visibility calculation that determines how many
//  blocks are fully hidden above or below the scroll viewport.
//  Uses hourHeight=60 so 1pt = 1min for easy math.
//
//  With hourHeight=60, gridVerticalPadding=16, blockExtraOffset=8:
//  A block at 10:00 AM → blockTop = 16 + 600 + 8 = 624
//  A 1-hour block height = max(1*60 - 8, 16) = 52
//  So blockBottom = 624 + 52 = 676
//

import Testing
import Foundation
import CoreGraphics
@testable import journalcalendar

@Suite("OffscreenBlockCounter — visibility calculations")
struct OffscreenBlockCounterTests {
    
    let counter = OffscreenBlockCounter(
        layout: BlockLayoutEngine(hourHeight: 60)
    )
    
    /// A block at 10AM with a viewport covering 600..800 is fully visible.
    /// blockTop=624, blockBottom=676 — both within 600..800.
    @Test func allBlocksVisible() {
        let block = makeBlock(startHour: 10, endHour: 11)
        let result = counter.count(blocks: [block], scrollOffset: 600, viewportHeight: 200)
        #expect(result.aboveCount == 0)
        #expect(result.belowCount == 0)
    }
    
    /// A block at 2AM (blockTop=144, blockBottom=196) is fully above
    /// a viewport starting at 600.
    @Test func blockFullyAboveViewport() {
        let block = makeBlock(startHour: 2, endHour: 3)
        let result = counter.count(blocks: [block], scrollOffset: 600, viewportHeight: 400)
        #expect(result.aboveCount == 1)
        #expect(result.belowCount == 0)
    }
    
    /// A block at 8PM (blockTop=1224) is fully below a viewport
    /// covering 0..400.
    @Test func blockFullyBelowViewport() {
        let block = makeBlock(startHour: 20, endHour: 21)
        let result = counter.count(blocks: [block], scrollOffset: 0, viewportHeight: 400)
        #expect(result.aboveCount == 0)
        #expect(result.belowCount == 1)
    }
    
    /// Three blocks: one above, one visible, one below.
    @Test func mixedVisibility() {
        let early = makeBlock(title: "Early", startHour: 2, endHour: 3)
        let visible = makeBlock(title: "Visible", startHour: 10, endHour: 11)
        let late = makeBlock(title: "Late", startHour: 20, endHour: 21)
        let result = counter.count(
            blocks: [early, visible, late],
            scrollOffset: 600,
            viewportHeight: 200
        )
        #expect(result.aboveCount == 1)
        #expect(result.belowCount == 1)
    }
    
    /// No blocks means both counts are zero.
    @Test func emptyBlocksReturnsZeros() {
        let result = counter.count(blocks: [], scrollOffset: 0, viewportHeight: 400)
        #expect(result.aboveCount == 0)
        #expect(result.belowCount == 0)
    }
    
    /// A block that is partially visible (top half clipped by viewport)
    /// should NOT be counted — only fully hidden blocks count.
    /// Block at 10AM: blockTop=624, blockBottom=676.
    /// Viewport starts at 650 — block's top is above but bottom is in view.
    @Test func partiallyVisibleBlockNotCounted() {
        let block = makeBlock(startHour: 10, endHour: 11)
        let result = counter.count(blocks: [block], scrollOffset: 650, viewportHeight: 200)
        #expect(result.aboveCount == 0)
        #expect(result.belowCount == 0)
    }
}
