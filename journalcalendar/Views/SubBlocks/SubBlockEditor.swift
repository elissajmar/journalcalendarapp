//
//  SubBlockEditor.swift
//  journalcalendar
//
//  Reusable editor for managing a list of sub-blocks.
//  Used by both AddEventBlock and EventBlockDetailEdit.
//

import SwiftUI

struct SubBlockEditor: View {
    @Binding var subBlocks: [SubBlock]
    
    @State private var expandedStates: [UUID: Bool] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 48) {
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
                        imageData: imagesBinding(for: id),
                        isExpanded: expandedBinding(for: id),
                        onRemove: { removeSubBlock(id: id) }
                    )
                case .link(let id, _):
                    LinkSubBlockEdit(
                        url: linkBinding(for: id),
                        isExpanded: expandedBinding(for: id),
                        onRemove: { removeSubBlock(id: id) }
                    )
                case .location(let id, _, _, _):
                    LocationSubBlockEdit(
                        locationName: locationNameBinding(for: id),
                        latitude: locationLatBinding(for: id),
                        longitude: locationLngBinding(for: id),
                        isExpanded: expandedBinding(for: id),
                        onRemove: { removeSubBlock(id: id) }
                    )
                }
            }
            
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
                newSubBlock = .images(imageData: [])
            case .link:
                newSubBlock = .link(url: "")
            case .location:
                newSubBlock = .location(name: "", latitude: 0, longitude: 0)
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
    
    private func imagesBinding(for id: UUID) -> Binding<[Data]> {
        Binding(
            get: {
                if let subBlock = subBlocks.first(where: { $0.id == id }),
                   case .images(_, let data) = subBlock {
                    return data
                }
                return []
            },
            set: { newValue in
                if let index = subBlocks.firstIndex(where: { $0.id == id }) {
                    subBlocks[index] = .images(id: id, imageData: newValue)
                }
            }
        )
    }
    
    private func linkBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: {
                if let subBlock = subBlocks.first(where: { $0.id == id }),
                   case .link(_, let url) = subBlock {
                    return url
                }
                return ""
            },
            set: { newValue in
                if let index = subBlocks.firstIndex(where: { $0.id == id }) {
                    subBlocks[index] = .link(id: id, url: newValue)
                }
            }
        )
    }
    
    private func locationNameBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: {
                if let subBlock = subBlocks.first(where: { $0.id == id }),
                   case .location(_, let name, _, _) = subBlock {
                    return name
                }
                return ""
            },
            set: { newValue in
                if let index = subBlocks.firstIndex(where: { $0.id == id }),
                   case .location(let id, _, let lat, let lng) = subBlocks[index] {
                    subBlocks[index] = .location(id: id, name: newValue, latitude: lat, longitude: lng)
                }
            }
        )
    }
    
    private func locationLatBinding(for id: UUID) -> Binding<Double> {
        Binding(
            get: {
                if let subBlock = subBlocks.first(where: { $0.id == id }),
                   case .location(_, _, let lat, _) = subBlock {
                    return lat
                }
                return 0
            },
            set: { newValue in
                if let index = subBlocks.firstIndex(where: { $0.id == id }),
                   case .location(let id, let name, _, let lng) = subBlocks[index] {
                    subBlocks[index] = .location(id: id, name: name, latitude: newValue, longitude: lng)
                }
            }
        )
    }
    
    private func locationLngBinding(for id: UUID) -> Binding<Double> {
        Binding(
            get: {
                if let subBlock = subBlocks.first(where: { $0.id == id }),
                   case .location(_, _, _, let lng) = subBlock {
                    return lng
                }
                return 0
            },
            set: { newValue in
                if let index = subBlocks.firstIndex(where: { $0.id == id }),
                   case .location(let id, let name, let lat, _) = subBlocks[index] {
                    subBlocks[index] = .location(id: id, name: name, latitude: lat, longitude: newValue)
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
    
    // MARK: - Public
    
    /// Call this to expand all sub-blocks (e.g., when loading existing data)
    func expandAll() -> SubBlockEditor {
        // This is handled by the default expandedStates returning true
        return self
    }
}
