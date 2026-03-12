//
//  EventBlockDetail.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/11/26.
//

import SwiftUI

struct EventBlockDetail: View {
    @Environment(\.dismiss) private var dismiss
    
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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title and time
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(timeRangeString)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Journal section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("JOURNAL")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        Text(placeholderJournalText)
                            .font(.body)
                            .lineSpacing(4)
                    }
                    
                    // Images section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("IMAGES")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        // Placeholder image grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(0..<3, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay {
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundStyle(.gray)
                                    }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            // TODO: Edit action
                        } label: {
                            Image(systemName: "pencil")
                                .font(.body)
                        }
                        
                        Button {
                            // TODO: Delete action
                        } label: {
                            Image(systemName: "trash")
                                .font(.body)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        
        let start = formatter.string(from: startTime).uppercased()
        let end = formatter.string(from: endTime).uppercased()
        
        return "\(start) - \(end)"
    }
    
    private var placeholderJournalText: String {
        """
        Uyen and I went to brunch at this new spot downtown. The weather was perfect for sitting outside. We ordered the avocado toast and the pancakes to share.
        
        She told me about her new job and how excited she is to start next month. I'm so happy for her - this is exactly what she's been working towards.
        
        We stayed for almost two hours just catching up. It's been too long since we had time like this together. Made plans to do this more regularly.
        """
    }
}

#Preview {
    let calendar = Calendar.current
    let now = Date()
    
    let startTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now)!
    let endTime = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: now)!
    
    return EventBlockDetail(
        title: "Brunch with Uyen",
        date: now,
        startTime: startTime,
        endTime: endTime
    )
}
