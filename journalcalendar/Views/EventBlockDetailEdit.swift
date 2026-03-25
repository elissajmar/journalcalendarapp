//
//  EventBlockDetailEdit.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/12/26.
//

import SwiftUI

struct EventBlockDetailEdit: View {
    @Environment(\.dismiss) var dismiss
    @Environment(ModelData.self) var modelData
    
    var blockId: UUID
    
    @State private var title: String = ""
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var subBlocks: [SubBlock] = []
    @State private var showDeleteAlert: Bool = false
    
    private var block: Block? {
        modelData.blocks.first(where: { $0.id == blockId })
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 48) {
                // Title and time
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Event title", text: $title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
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
        .navigationBarBackButtonHidden(true)
        .alert("Delete Event", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteBlock()
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body)
                        .foregroundStyle(.primary)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button {
                        saveChanges()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.body)
                            Text("Save")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .foregroundStyle(.primary)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .onAppear {
            loadBlockData()
        }
    }
    
    // MARK: - Data Management
    
    private func loadBlockData() {
        guard let block = block else { return }
        title = block.title
        startTime = block.startTime
        endTime = block.endTime
        subBlocks = block.subBlocks
    }
    
    private func saveChanges() {
        modelData.updateBlock(
            id: blockId,
            title: title,
            startTime: startTime,
            endTime: endTime,
            subBlocks: subBlocks
        )
        dismiss()
    }
    
    private func deleteBlock() {
        modelData.deleteBlock(id: blockId)
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
        }
    }
}

#Preview {
    @Previewable @State var showSheet = true
    let modelData = ModelData()
    
    return NavigationStack {
        Color.clear
            .sheet(isPresented: $showSheet) {
                NavigationStack {
                    EventBlockDetailEdit(blockId: ModelData.sampleBlock.id)
                        .environment(modelData)
                }
            }
            .onAppear {
                showSheet = true
            }
    }
}
