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
    @Environment(AuthController.self) var auth
    
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
                            .font(.heading3)
                            .foregroundStyle(title.isEmpty ? Color("TextSecondary") : Color("TextPrimary"))
                            .textFieldStyle(.plain)
                        
                        HStack(spacing: 12) {
                            DatePicker("", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            
                            Text("to")
                                .labelStyle()
                            
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
                            .foregroundStyle(Color("TextPrimary"))
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
                                .foregroundStyle(Color("TextSecondary"))
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            createBlock()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                Text("Create")
                            }
                            .font(.label)
                            .textCase(.uppercase)
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
        guard let userId = auth.currentUserId else { return }
        Task {
            await modelData.createBlock(
                title: title,
                startTime: startTime,
                endTime: endTime,
                subBlocks: subBlocks,
                userId: userId
            )
        }
        dismiss()
    }
}

#Preview {
    @Previewable @State var showSheet = true
    let modelData = ModelData.preview()
    
    return Color.clear
        .sheet(isPresented: $showSheet) {
            AddEventBlock(initialDate: Date())
                .environment(modelData)
        }
        .onAppear {
            showSheet = true
        }
}
