//
//  EventBlock.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/11/26.
//

import SwiftUI

struct EventBlock: View {
    private let block: Block
    private let onTap: () -> Void
    
    init(block: Block, onTap: @escaping () -> Void = {}) {
        self.block = block
        self.onTap = onTap
    }
    
    var body: some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
    }
    
    private var content: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let showLocation = height >= 90 && block.locationName != nil
            let showStats = height >= 110
            
            VStack(alignment: .leading, spacing: 0) {
                // Top section: title, time, location
                VStack(alignment: .leading, spacing: 2) {
                    Text(block.title)
                        .font(.paragraph1)
                        .fontWeight(.medium)
                        .lineLimit(height < 60 ? 1 : 2)
                        .truncationMode(.tail)
                    
                    if height >= 50 {
                        Text(timeRangeString)
                            .labelStyle()
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    
                    if showLocation, let locationName = block.locationName {
                        Label(locationName, systemImage: "mappin.and.ellipse")
                            .labelStyle()
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                
                if showStats {
                    Spacer(minLength: 0)
                    
                    // Bottom section: stats
                    HStack(spacing: 12) {
                        if !block.journalText.isEmpty {
                            Label("\(wordCount)", systemImage: "text.alignleft")
                                .labelStyle()
                                .lineLimit(1)
                        }
                        
                        if block.imageCount > 0 {
                            Label("\(block.imageCount)", systemImage: "photo")
                                .labelStyle()
                                .lineLimit(1)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .padding(.trailing, 4)
    }
    
    // MARK: - Helpers
    
    private var wordCount: Int {
        let words = block.journalText.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    private var timeRangeString: String {
        DateFormatters.timeRange(from: block.startTime, to: block.endTime)
    }
}

#Preview {
    EventBlock(block: ModelData.sampleBlock)
        .frame(height: 120)
        .padding()
}
