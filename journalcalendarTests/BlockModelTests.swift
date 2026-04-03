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
    // Filters sub-blocks for .journal cases and extracts their text.
    // The app only allows one journal sub-block per block (the add menu
    // hides types that already exist), so the typical case is a single entry.
    
    /// A block with a single journal sub-block returns that text directly.
    @Test func journalTextReturnsSingleEntry() {
        let block = makeBlock(
            startHour: 10, endHour: 11,
            subBlocks: [
                .journal(text: "Had a great day at the park")
            ]
        )
        #expect(block.journalText == "Had a great day at the park")
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
    
    /// An empty journal string is still returned — the UI is responsible
    /// for deciding whether to display it based on isEmpty.
    @Test func journalTextReturnsEmptyStringEntry() {
        let block = makeBlock(
            startHour: 10, endHour: 11,
            subBlocks: [.journal(text: "")]
        )
        #expect(block.journalText == "")
    }
    
    // MARK: - locationName
    // Returns the name of the first location sub-block with a non-empty name.
    // Empty-string locations are skipped. Returns nil if no match is found.
    // The app only allows one location sub-block per block.
    
    /// A location sub-block with a valid name is returned.
    @Test func locationNameReturnsName() {
        let block = makeBlock(
            startHour: 10, endHour: 11,
            subBlocks: [
                .location(name: "Central Park", latitude: 40.78, longitude: -73.97)
            ]
        )
        #expect(block.locationName == "Central Park")
    }
    
    /// A location sub-block with an empty name is treated as "no location" —
    /// locationName returns nil. This can happen when the user adds a location
    /// sub-block but hasn't searched/selected a place yet.
    @Test func locationNameNilWhenNameIsEmpty() {
        let block = makeBlock(
            startHour: 10, endHour: 11,
            subBlocks: [
                .location(name: "", latitude: 0, longitude: 0)
            ]
        )
        #expect(block.locationName == nil)
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
    // Returns the count of image Data objects in the .images sub-block.
    // The app only allows one .images sub-block per block.
    
    /// An images sub-block with 3 photos reports imageCount of 3.
    @Test func imageCountReturnsPhotoCount() {
        let block = makeBlock(
            startHour: 10, endHour: 11,
            subBlocks: [
                .images(imageData: [Data(), Data(), Data()])
            ]
        )
        #expect(block.imageCount == 3)
    }
    
    /// An images sub-block with an empty array (user added the section
    /// but hasn't picked photos yet) reports imageCount of 0.
    @Test func imageCountZeroWhenNoPhotosAdded() {
        let block = makeBlock(
            startHour: 10, endHour: 11,
            subBlocks: [
                .images(imageData: [])
            ]
        )
        #expect(block.imageCount == 0)
    }
    
    /// A block with no images sub-block at all also reports 0.
    @Test func imageCountZeroWhenNoImagesSubBlock() {
        let block = makeBlock(
            startHour: 10, endHour: 11,
            subBlocks: [
                .journal(text: "Just text")
            ]
        )
        #expect(block.imageCount == 0)
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
    
    /// Each SubBlock case stores its own UUID. Passing a specific ID in
    /// should be reflected back by the .id computed property. This matters
    /// because SubBlockEditor uses IDs to create bindings for each sub-block.
    @Test func subBlockIdIsPreserved() {
        let customId = UUID()
        let journal = SubBlock.journal(id: customId, text: "test")
        #expect(journal.id == customId)
        
        let images = SubBlock.images(id: customId, imageData: [])
        #expect(images.id == customId)
        
        let link = SubBlock.link(id: customId, url: "https://example.com")
        #expect(link.id == customId)
        
        let location = SubBlock.location(id: customId, name: "", latitude: 0, longitude: 0)
        #expect(location.id == customId)
    }
    
    // MARK: - Edge cases
    
    /// A block with no sub-blocks at all should return safe defaults
    /// for all computed properties — empty text, nil location, 0 images.
    @Test func emptySubBlocksReturnDefaults() {
        let block = makeBlock(startHour: 10, endHour: 11, subBlocks: [])
        #expect(block.journalText == "")
        #expect(block.locationName == nil)
        #expect(block.imageCount == 0)
    }
}
