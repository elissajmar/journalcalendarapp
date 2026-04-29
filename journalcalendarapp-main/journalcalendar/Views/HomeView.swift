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
}

#Preview {
    HomeView()
        .environment(ModelData.preview())
        .environment(AuthController())
}
