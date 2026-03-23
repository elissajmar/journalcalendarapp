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
    @State private var expandedStates: [UUID: Bool] = [:]
    
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
                        }
                        .buttonStyle(.brown)
                    }
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
