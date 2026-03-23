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
    @State private var expandedStates: [UUID: Bool] = [:]
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
                
                // Dynamic sub-blocks
                ForEach(subBlocks) { subBlock in
                    switch subBlock {
                    case .journal(let id, _):
                        JournalSubBlockEdit(
                            text: journalBinding(for: id),
                            isExpanded: expandedBinding(for: id),
                            onRemove: { removeSubBlock(id: id) }
                        )
                    case .images(let id, _):
                        ImagesSubBlockEdit(
                            imageNames: imagesBinding(for: id),
                            isExpanded: expandedBinding(for: id),
                            onRemove: { removeSubBlock(id: id) }
                        )
                    }
                }
                
                // Add sub-blocks button
                if !availableSubBlockTypes.isEmpty {
                    Menu {
                        ForEach(availableSubBlockTypes) { type in
                            Button {
                                addSubBlock(ofType: type)
                            } label: {
                                Label(type.rawValue, systemImage: type.iconName)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                                .font(.body)
                            Text("Add sub-blocks")
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .foregroundStyle(.primary)
                        .cornerRadius(8)
                    }
                }
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
    
    // MARK: - Sub-Block Management
    
    private var availableSubBlockTypes: [SubBlockType] {
        let existingTypes = Set(subBlocks.map { $0.type })
        return SubBlockType.allCases.filter { !existingTypes.contains($0) }
    }
    
    private func addSubBlock(ofType type: SubBlockType) {
        withAnimation {
            let newSubBlock: SubBlock
            switch type {
            case .journal:
                newSubBlock = .journal(text: "")
            case .images:
                newSubBlock = .images(imageNames: [])
            }
            subBlocks.append(newSubBlock)
            expandedStates[newSubBlock.id] = true
        }
    }
    
    private func removeSubBlock(id: UUID) {
        withAnimation {
            subBlocks.removeAll { $0.id == id }
            expandedStates.removeValue(forKey: id)
        }
    }
    
    // MARK: - Bindings
    
    private func journalBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: {
                if let subBlock = subBlocks.first(where: { $0.id == id }),
                   case .journal(_, let text) = subBlock {
                    return text
                }
                return ""
            },
            set: { newValue in
                if let index = subBlocks.firstIndex(where: { $0.id == id }) {
                    subBlocks[index] = .journal(id: id, text: newValue)
                }
            }
        )
    }
    
    private func imagesBinding(for id: UUID) -> Binding<[String]> {
        Binding(
            get: {
                if let subBlock = subBlocks.first(where: { $0.id == id }),
                   case .images(_, let names) = subBlock {
                    return names
                }
                return []
            },
            set: { newValue in
                if let index = subBlocks.firstIndex(where: { $0.id == id }) {
                    subBlocks[index] = .images(id: id, imageNames: newValue)
                }
            }
        )
    }
    
    private func expandedBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { expandedStates[id] ?? true },
            set: { expandedStates[id] = $0 }
        )
    }
    
    // MARK: - Data Management
    
    private func loadBlockData() {
        guard let block = block else { return }
        title = block.title
        startTime = block.startTime
        endTime = block.endTime
        subBlocks = block.subBlocks
        for subBlock in subBlocks {
            expandedStates[subBlock.id] = true
        }
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
