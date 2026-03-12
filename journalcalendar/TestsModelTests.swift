//
//  ModelTests.swift
//  Calendar Journal
//
//  Created on 3/11/26.
//

import Testing
import Foundation
@testable import Calendar_Journal

@Suite("Journal Block Tests")
struct JournalBlockTests {
    
    @Test("Creating a journal block")
    func createJournalBlock() async throws {
        let block = JournalBlock(
            title: "Test Block",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600)
        )
        
        #expect(block.title == "Test Block")
        #expect(block.subBlocks.isEmpty)
        #expect(block.totalWordCount == 0)
        #expect(block.totalImageCount == 0)
    }
    
    @Test("Adding sub-blocks to journal block")
    func addSubBlocks() async throws {
        let block = JournalBlock(
            title: "Test Block",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600)
        )
        
        let textBlock = TextSubBlock(content: "This is a test entry.")
        block.addSubBlock(textBlock)
        
        #expect(block.subBlocks.count == 1)
        #expect(block.totalWordCount == 5) // "This is a test entry" = 5 words
    }
    
    @Test("Calculating duration")
    func calculateDuration() async throws {
        let start = Date()
        let end = start.addingTimeInterval(3600) // 1 hour
        
        let block = JournalBlock(
            title: "One Hour Block",
            startDate: start,
            endDate: end
        )
        
        #expect(block.duration == 3600.0)
    }
    
    @Test("Time range string formatting")
    func timeRangeString() async throws {
        let calendar = Calendar.current
        let today = Date()
        
        let start = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: today) ?? today
        let end = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: today) ?? today
        
        let block = JournalBlock(
            title: "Lunch",
            startDate: start,
            endDate: end
        )
        
        // Should be formatted like "11:00 AM - 1:00 PM"
        #expect(block.timeRangeString.contains("AM"))
        #expect(block.timeRangeString.contains("PM"))
        #expect(block.timeRangeString.contains("-"))
    }
}

@Suite("Text Sub-Block Tests")
struct TextSubBlockTests {
    
    @Test("Word count calculation")
    func wordCount() async throws {
        let text = TextSubBlock(content: "This has five words total.")
        #expect(text.wordCount == 5)
        
        let emptyText = TextSubBlock(content: "")
        #expect(emptyText.wordCount == 0)
        
        let multiLineText = TextSubBlock(content: """
        First line here.
        Second line here.
        Third line.
        """)
        #expect(multiLineText.wordCount == 9)
    }
    
    @Test("Empty text detection")
    func isEmpty() async throws {
        let empty = TextSubBlock(content: "")
        #expect(empty.isEmpty)
        
        let whitespace = TextSubBlock(content: "   \n  ")
        #expect(whitespace.isEmpty)
        
        let notEmpty = TextSubBlock(content: "Not empty")
        #expect(!notEmpty.isEmpty)
    }
    
    @Test("Preview text generation")
    func preview() async throws {
        let short = TextSubBlock(content: "Short text")
        #expect(short.preview == "Short text")
        
        let longContent = String(repeating: "a", count: 150)
        let long = TextSubBlock(content: longContent)
        #expect(long.preview.hasSuffix("..."))
        #expect(long.preview.count == 103) // 100 chars + "..."
    }
}

@Suite("Images Sub-Block Tests")
struct ImagesSubBlockTests {
    
    @Test("Adding images")
    func addImages() async throws {
        let imagesBlock = ImagesSubBlock()
        #expect(imagesBlock.isEmpty)
        #expect(imagesBlock.imageCount == 0)
        
        let image = ImageData.sample(caption: "Test")
        imagesBlock.addImage(image)
        
        #expect(!imagesBlock.isEmpty)
        #expect(imagesBlock.imageCount == 1)
    }
    
    @Test("Display name with count")
    func displayName() async throws {
        let imagesBlock = ImagesSubBlock()
        imagesBlock.addImage(ImageData.sample())
        imagesBlock.addImage(ImageData.sample())
        imagesBlock.addImage(ImageData.sample())
        
        #expect(imagesBlock.displayNameWithCount == "IMAGES (3)")
    }
    
    @Test("Removing images")
    func removeImages() async throws {
        let imagesBlock = ImagesSubBlock()
        let image1 = ImageData.sample()
        let image2 = ImageData.sample()
        
        imagesBlock.addImage(image1)
        imagesBlock.addImage(image2)
        #expect(imagesBlock.imageCount == 2)
        
        imagesBlock.removeImage(image1)
        #expect(imagesBlock.imageCount == 1)
        
        imagesBlock.removeImage(at: 0)
        #expect(imagesBlock.isEmpty)
    }
}

@Suite("Date Helper Tests")
struct DateHelperTests {
    
    @Test("Start and end of day")
    func dayBoundaries() async throws {
        let date = Date()
        let start = date.startOfDay
        let end = date.endOfDay
        
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: start)
        let startMinute = calendar.component(.minute, from: start)
        
        #expect(startHour == 0)
        #expect(startMinute == 0)
        
        // End should be 23:59:59
        #expect(end > start)
        #expect(end.timeIntervalSince(start) < 86400) // Less than 24 hours
    }
    
    @Test("Date navigation")
    func dateNavigation() async throws {
        let today = Date()
        let yesterday = today.previousDay
        let tomorrow = today.nextDay
        
        #expect(yesterday < today)
        #expect(tomorrow > today)
        
        let dayDiff = Calendar.current.dateComponents([.day], from: yesterday, to: tomorrow)
        #expect(dayDiff.day == 2)
    }
    
    @Test("Setting time on date")
    func settingTime() async throws {
        let date = Date()
        let newDate = date.settingTime(hour: 15, minute: 30)
        
        #expect(newDate.hour == 15)
        #expect(newDate.minute == 30)
    }
    
    @Test("Date formatting")
    func formatting() async throws {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 15, minute: 30)) ?? Date()
        
        let dayHeader = date.formattedDayHeader
        #expect(dayHeader.contains("Mar"))
        #expect(dayHeader.contains("10"))
        
        let time = date.formattedTime
        #expect(time.contains("3:30"))
        #expect(time.contains("PM"))
    }
}

@Suite("Sub-Block Type Tests")
struct SubBlockTypeTests {
    
    @Test("Display names")
    func displayNames() async throws {
        #expect(SubBlockType.text.displayName == "JOURNAL")
        #expect(SubBlockType.images.displayName == "IMAGES")
        #expect(SubBlockType.link.displayName == "LINK")
        #expect(SubBlockType.checkbox.displayName == "CHECKLIST")
    }
    
    @Test("Icon names")
    func iconNames() async throws {
        #expect(SubBlockType.text.iconName == "text.alignleft")
        #expect(SubBlockType.images.iconName == "photo.on.rectangle")
        #expect(!SubBlockType.link.iconName.isEmpty)
        #expect(!SubBlockType.checkbox.iconName.isEmpty)
    }
}
