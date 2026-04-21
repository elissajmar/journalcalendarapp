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
    @Environment(AuthController.self) var auth
    
    var blockId: UUID
    
    @State private var title: String = ""
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var recurrence: Recurrence = .never
    @State private var subBlocks: [SubBlock] = []
    @State private var showDeleteAlert: Bool = false
    @State private var showRecurringDeleteDialog: Bool = false
    
    private var block: Block? {
        modelData.blocks.first(where: { $0.id == blockId })
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 48) {
                // Title and time
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Event title", text: $title)
                        .font(.heading3)
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

                    Picker(selection: $recurrence) {
                        ForEach(Recurrence.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    } label: {
                        Text(recurrence.displayName)
                    }
                    .pickerStyle(.menu)
                    .font(.label)
                    .textCase(.uppercase)
                    .tint(.primary)
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
        .confirmationDialog("Delete Recurring Event", isPresented: $showRecurringDeleteDialog, titleVisibility: .visible) {
            Button("Delete This Event", role: .destructive) {
                deleteThisInstance()
            }
            Button("Delete This and All Future Events", role: .destructive) {
                deleteThisAndFuture()
            }
            Button("Delete All Events", role: .destructive) {
                deleteBlock()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This is a recurring event.")
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
                        if let block = block, block.recurrence != .never {
                            showRecurringDeleteDialog = true
                        } else {
                            showDeleteAlert = true
                        }
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
                            Text("Save")
                        }
                        .font(.label)
                        .textCase(.uppercase)
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
        recurrence = block.recurrence
        subBlocks = block.subBlocks
    }
    
    private func saveChanges() {
        guard let userId = auth.currentUserId else { return }
        Task {
            await modelData.updateBlock(
                id: blockId,
                title: title,
                startTime: startTime,
                endTime: endTime,
                recurrence: recurrence,
                subBlocks: subBlocks,
                userId: userId
            )
        }
        dismiss()
    }
    
    private func deleteBlock() {
        Task {
            await modelData.deleteBlock(id: blockId)
        }
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
        }
    }

    private func deleteThisInstance() {
        guard let block = block else { return }
        Task {
            await modelData.deleteBlockInstance(id: blockId, date: block.date)
        }
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
        }
    }

    private func deleteThisAndFuture() {
        guard let block = block else { return }
        Task {
            await modelData.deleteBlockAndFuture(id: blockId, fromDate: block.date)
        }
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
        }
    }
}

#Preview {
    @Previewable @State var showSheet = true
    let modelData = ModelData.preview()
    
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
