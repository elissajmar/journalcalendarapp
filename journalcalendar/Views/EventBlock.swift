//
//  EventBlock.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/11/26.
//

import SwiftUI

struct EventBlock: View {
    private let title: String
    private let date: Date
    private let startTime: Date
    private let endTime: Date
    
    init(title: String, date: Date, startTime: Date, endTime: Date) {
        self.title = title
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text(timeRangeString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Stats row (placeholder for now)
            HStack(spacing: 16) {
                Label("527", systemImage: "text.alignleft")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Label("3", systemImage: "photo")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .padding(.trailing, 16)
    }
    
    // MARK: - Helpers
    
    private var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        
        let start = formatter.string(from: startTime).uppercased()
        let end = formatter.string(from: endTime).uppercased()
        
        return "\(start) - \(end)"
    }
}

#Preview {
    let calendar = Calendar.current
    let now = Date()
    
    let startTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now)!
    let endTime = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: now)!
    
    return EventBlock(
        title: "Brunch with Uyen",
        date: now,
        startTime: startTime,
        endTime: endTime
    )
    .padding()
}
