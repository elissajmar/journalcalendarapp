//
//  AddEventBlock.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/13/26.
//

import SwiftUI

struct AddEventBlock: View {
    @Environment(\.dismiss) var dismiss
    @Environment(ModelData.self) var modelData
    
    var initialDate: Date
    
    @State private var title: String = ""
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var subBlocks: [SubBlock] = []
    
    init(initialDate: Date) {
        self.initialDate = initialDate
        
        // Set default times: start at next hour, end 1 hour later
        let calendar = Calendar.current
        let now = initialDate
        let currentHour = calendar.component(.hour, from: now)
        let nextHour = (currentHour + 1) % 24
        
        let startDate = calendar.date(bySettingHour: nextHour, minute: 0, second: 0, of: now) ?? now
        let endDate = calendar.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        
        _startTime = State(initialValue: startDate)
        _endTime = State(initialValue: endDate)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 48) {
                    // Title and time
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Add title", text: $title)
                            .font(.largeTitle)
                            .fontWeight(.medium)
                            .foregroundStyle(title.isEmpty ? .secondary : .primary)
                            .textFieldStyle(.plain)
                        
                        HStack(spacing: 12) {
                            DatePicker("", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            
                            Text("to")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            
                            DatePicker("", selection: $endTime, displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                    }
                    
                    SubBlockEditor(subBlocks: $subBlocks)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "trash")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            createBlock()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .font(.body)
                                Text("Create")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(title.isEmpty)
                        .opacity(title.isEmpty ? 0.5 : 1.0)
                    }
                }
            }
        }
    }
    
    // MARK: - Data Management
    
    private func createBlock() {
        modelData.createBlock(
            title: title,
            startTime: startTime,
            endTime: endTime,
            subBlocks: subBlocks
        )
        dismiss()
    }
}

#Preview {
    @Previewable @State var showSheet = true
    let modelData = ModelData()
    
    return Color.clear
        .sheet(isPresented: $showSheet) {
            AddEventBlock(initialDate: Date())
                .environment(modelData)
        }
        .onAppear {
            showSheet = true
        }
}
