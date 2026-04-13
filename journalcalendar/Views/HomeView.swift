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
    @Environment(AuthController.self) var auth

    @State private var selectedDate = Date()
    @State private var selectedBlockId: UUID?
    @State private var showAddBlock = false
    
    @State private var hourHeight: CGFloat = 120
    @State private var scrollOffset: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0
    
    private var drag: BlockDragHelper { BlockDragHelper(hourHeight: hourHeight) }
    
    private var offscreenCounts: OffscreenBlockCounter.Result {
        let counter = OffscreenBlockCounter(layout: BlockLayoutEngine(hourHeight: hourHeight))
        return counter.count(blocks: todaysBlocks, scrollOffset: scrollOffset, viewportHeight: viewportHeight)
    }
    
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
                        hourHeight: $hourHeight,
                        onBlockTapped: { block in
                            selectedBlockId = block.id
                        },
                        onBlockDragFinished: { block, translation in
                            finishDrag(for: block, translation: translation)
                        }
                    )
                    .pinchToZoom(hourHeight: $hourHeight, min: 40, max: 240)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geo in
                    geo.contentOffset.y + geo.contentInsets.top
                } action: { _, newValue in
                    scrollOffset = newValue
                }
                .onScrollGeometryChange(for: CGFloat.self) { geo in
                    geo.visibleRect.height
                } action: { _, newValue in
                    viewportHeight = newValue
                }
                .onAppear {
                    proxy.scrollTo(8, anchor: .top)
                }
            }
            .overlay(alignment: .top) {
                if offscreenCounts.aboveCount > 0 {
                    MoreEventsPill(count: offscreenCounts.aboveCount, direction: .up)
                        .padding(.top, 8)
                        .transition(.opacity)
                }
            }
            .overlay(alignment: .bottom) {
                if offscreenCounts.belowCount > 0 {
                    MoreEventsPill(count: offscreenCounts.belowCount, direction: .down)
                        .padding(.bottom, 8)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: offscreenCounts.aboveCount)
            .animation(.easeInOut(duration: 0.25), value: offscreenCounts.belowCount)
        }
        .background(Color("AppBackground"))
        .sheet(item: $selectedBlockId) { blockId in
            EventBlockDetail(blockId: blockId)
                .environment(modelData)
                .environment(auth)
        }
        .task(id: selectedDate) {
            guard let userId = auth.currentUserId else { return }
            await modelData.fetchBlocks(for: selectedDate, userId: userId)
        }
        .sheet(isPresented: $showAddBlock) {
            AddEventBlock(initialDate: selectedDate)
                .environment(modelData)
                .environment(auth)
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
                .heading2Style()
            
            Spacer()
            
            // Sign out button
            Button {
                Task { try? await auth.signOut() }
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            // Add Block button
            Button(action: { showAddBlock = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Block")
                }
                .font(.label)
                .textCase(.uppercase)
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
        guard let userId = auth.currentUserId else { return }
        
        Task {
            await modelData.updateBlock(
                id: block.id,
                title: block.title,
                startTime: newTimes.start,
                endTime: newTimes.end,
                recurrence: block.recurrence,
                subBlocks: block.subBlocks,
                userId: userId
            )
        }
    }
}

#Preview {
    HomeView()
        .environment(ModelData.preview())
}
