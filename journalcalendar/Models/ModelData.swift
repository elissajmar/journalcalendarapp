//
//  ModelData.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/11/26.
//

import Foundation

@Observable
class ModelData {
    var blocks: [Block] = []
    
    init() {
        // Load sample data
        blocks = [sampleBlock]
    }
    
    // MARK: - Sample Data
    
    static var sampleBlock: Block {
        let calendar = Calendar.current
        
        // Create date for March 11, 2026
        var dateComponents = DateComponents()
        dateComponents.year = 2026
        dateComponents.month = 3
        dateComponents.day = 11
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let date = calendar.date(from: dateComponents)!
        
        // Create start time (10:00 AM)
        var startComponents = dateComponents
        startComponents.hour = 10
        startComponents.minute = 0
        let startTime = calendar.date(from: startComponents)!
        
        // Create end time (11:00 AM)
        var endComponents = dateComponents
        endComponents.hour = 11
        endComponents.minute = 0
        let endTime = calendar.date(from: endComponents)!
        
        return Block(
            date: date,
            startTime: startTime,
            endTime: endTime,
            title: "Brunch with Uyen"
        )
    }
}
