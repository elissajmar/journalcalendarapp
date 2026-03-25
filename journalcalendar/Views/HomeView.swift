//
//  HomeView.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/11/26.
//

import SwiftUI

// Wrapper to make UUID work with sheet(item:)
extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

struct HomeView: View {
    @Environment(ModelData.self) var modelData

    @State private var selectedDate = Date()
    @State private var selectedBlockId: UUID?
    @State private var showAddBlock = false
    
    private let hourHeight: CGFloat = 120
    private var drag: BlockDragHelper { BlockDragHelper(hourHeight: hourHeight) }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with date and Block button
            header
            
            Divider()
            
            // Calendar view with time slots
            ScrollViewReader { proxy in
                ScrollView {
                    CalendarGridView(
                        blocks: todaysBlocks,
                        onBlockTapped: { block in
                            selectedBlockId = block.id
                        },
                        onBlockDragFinished: { block, translation in
                            finishDrag(for: block, translation: translation)
                        }
                    )
                }
                .onAppear {
                    proxy.scrollTo(8, anchor: .top)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(item: $selectedBlockId) { blockId in
            EventBlockDetail(blockId: blockId)
                .environment(modelData)
        }
        .sheet(isPresented: $showAddBlock) {
            AddEventBlock(initialDate: selectedDate)
                .environment(modelData)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 16) {
            // Navigation arrows
            Button(action: { previousDay() }) {
                Image(systemName: "chevron.left")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Button(action: { nextDay() }) {
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            // Date display
            Text(DateFormatters.shortDate(from: selectedDate))
                .font(.title2)
                .fontWeight(.medium)
            
            Spacer()
            
            // Add Block button
            Button(action: { showAddBlock = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Block")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.brown)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
    
    // MARK: - Helpers
    
    private var todaysBlocks: [Block] {
        let calendar = Calendar.current
        return modelData.blocks.filter { block in
            calendar.isDate(block.startTime, inSameDayAs: selectedDate)
        }
    }
    
    private func previousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func nextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
    
    private func finishDrag(for block: Block, translation: CGFloat) {
        guard let newTimes = drag.newTimes(for: block, translation: translation) else {
            return
        }
        
        modelData.updateBlock(
            id: block.id,
            title: block.title,
            startTime: newTimes.start,
            endTime: newTimes.end,
            subBlocks: block.subBlocks
        )
    }
}

#Preview {
    HomeView()
        .environment(ModelData())
}
