//
//  BlockModelTests.swift
//  journalcalendarTests
//
//  Tests for Block's computed properties (journalText, locationName,
//  imageCount) and SubBlock's type mapping. These properties use
//  pattern matching on the SubBlock enum to aggregate data — getting
//  the filtering and joining logic wrong could silently return empty
//  or incorrect values in the UI.
//

import Testing
import Foundation
@testable import journalcalendar

@Suite("Block model — computed properties and SubBlock behavior")
struct BlockModelTests {
    
    // MARK: - journalText
    // Filters sub-blocks for .journal cases and joins their text
    // with double newlines. Non-journal sub-blocks are ignored.
    
    /// Two journal sub-blocks should be joined with "\n\n" separator.
    @Test func journalTextJoinsMultipleEntries() {
        let block = makeBlock(
            startHour: 10, endHour: 11,
            subBlocks: [
                .journal(text: "First entry"),
                .journal(text: "Second entry")
            ]
        )
        #expect(block.journalText == "First entry\n\nSecond entry")
    }
    
    /// A block with no journal sub-blocks returns an empty string.
    /// This is important for the UI — it checks journalText.isEmpty
    /// to decide whether to show the journal section.
    @Test func journalTextEmptyWhenNoJournals() {
        let block = makeBlock(
            startHour: 10, endHour: 11,
            subBlocks: [
                .images(imageData: [Data()]),
                .link(url: "https://example.com")
            ]
        )
        #expect(block.journalText == "")
    }
    
    /// Only .journal sub-blocks contribute to journalText.
    /// Images, links, and locations should be completely ignored.
    @Test func journalTextIgnoresOtherSubBlockTypes() {
        let block = makeBlock(
            startHour: 10, endHour: 11,
            subBlocks: [
                .images(imageData: [Data()]),
                .journal(text: "Only journal"),
                .link(url: "https://example.com"),
                .location(name: "Park", latitude: 0, longitude: 0)
            ]
        )
        #expect(block.journalText == "Only journal")
    }
    
    // MARK: - locationName
    // Returns the name of the first location sub-block with a non-empty name.
    // Empty-string locations are skipped. Returns nil if no location is found.
    
    /// When the first location has an empty name, it should be skipped
    /// and the second location's name should be returned instead.
    @Test func locationNameReturnsFirstNonEmpty() {
        let block = makeBlock(
            startHour: 10, endHour: 11,
            subBlocks: [
                .location(name: "", latitude: 0, longitude: 0),
                .location(name: "Central Park", latitude: 40.78, longitude: -73.97)
            ]
        )
        #expect(block.locationName == "Central Park")
    }
    
    /// A block with no location sub-blocks at all returns nil.
    @Test func locationNameNilWhenNoLocations() {
        let block = makeBlock(
            startHour: 10, endHour: 11,
            subBlocks: [
                .journal(text: "Just a note")
            ]
        )
        #expect(block.locationName == nil)
    }
    
    // MARK: - imageCount
    // Sums the count of image Data objects across all .images sub-blocks.
    // A block can have multiple .images sub-blocks (e.g., added at different times).
    
    /// Two image sub-blocks with 2 and 1 images respectively → total of 3.
    @Test func imageCountSumsAcrossMultipleSubBlocks() {
        let block = makeBlock(
            startHour: 10, endHour: 11,
            subBlocks: [
                .images(imageData: [Data(), Data()]),
                .images(imageData: [Data()])
            ]
        )
        #expect(block.imageCount == 3)
    }
    
    // MARK: - SubBlock.type
    // Each enum case maps to a SubBlockType value. This mapping is used
    // throughout the UI for icons, section headers, and add-sub-block menus.
    
    /// Verify each SubBlock case returns the correct SubBlockType.
    @Test func subBlockTypeMapping() {
        let journal = SubBlock.journal(text: "test")
        let images = SubBlock.images(imageData: [])
        let link = SubBlock.link(url: "https://example.com")
        let location = SubBlock.location(name: "Test", latitude: 0, longitude: 0)
        
        #expect(journal.type == .journal)
        #expect(images.type == .images)
        #expect(link.type == .link)
        #expect(location.type == .location)
    }
}
