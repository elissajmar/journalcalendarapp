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

    @State private var isMonthlyView = false
    @State private var selectedBlockId: UUID?
    @State private var showAddBlock = false
    @State private var selectedDate: Date?

    var body: some View {
        ZStack {
            if isMonthlyView {
                MonthlyCalendarView(isMonthlyView: $isMonthlyView) { date in
                    selectedDate = date
                    withAnimation(.easeInOut(duration: 0.35)) {
                        isMonthlyView = false
                    }
                }
                .transition(.move(edge: .leading))
            } else {
                DayCalendarView(
                    isMonthlyView: $isMonthlyView,
                    selectedBlockId: $selectedBlockId,
                    showAddBlock: $showAddBlock,
                    initialDate: selectedDate
                )
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isMonthlyView)
        .sheet(item: $selectedBlockId) { blockId in
            EventBlockDetail(blockId: blockId)
                .environment(modelData)
                .environment(auth)
        }
        .sheet(isPresented: $showAddBlock) {
            AddEventBlock(initialDate: selectedDate ?? Date())
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
