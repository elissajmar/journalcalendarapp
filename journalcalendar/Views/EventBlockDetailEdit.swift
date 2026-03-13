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
    @State private var journalText: String = ""
    @State private var isJournalExpanded: Bool = true
    @State private var isImagesExpanded: Bool = true
    @State private var showDeleteAlert: Bool = false
    
    private var block: Block? {
        modelData.blocks.first(where: { $0.id == blockId })
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title field
                TextField("Event title", text: $title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .textFieldStyle(.plain)
                
                // Date and time pickers
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
                
                // Journal section
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        withAnimation {
                            isJournalExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "book")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("JOURNAL")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    isJournalExpanded.toggle()
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if isJournalExpanded {
                        VStack(alignment: .leading, spacing: 8) {
                            TextEditor(text: $journalText)
                                .font(.body)
                                .lineSpacing(4)
                                .frame(minHeight: 300)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .background(Color(uiColor: .secondarySystemBackground))
                                .cornerRadius(8)
                            
                            Text("\(wordCount) words")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Images section
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        withAnimation {
                            isImagesExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("IMAGES (3)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    isImagesExpanded.toggle()
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if isImagesExpanded {
                        VStack(alignment: .leading, spacing: 12) {
                            // Placeholder image grid
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(0..<3, id: \.self) { index in
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.3))
                                        .aspectRatio(1, contentMode: .fit)
                                        .overlay {
                                            Image(systemName: "photo")
                                                .font(.largeTitle)
                                                .foregroundStyle(.gray)
                                        }
                                }
                            }
                            
                            // Upload button placeholder
                            Button {
                                // TODO: Implement image upload
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.up.circle")
                                        .font(.body)
                                    Text("Upload")
                                        .font(.body)
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Add sub-blocks button placeholder
                Button {
                    // TODO: Implement add sub-blocks
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
    
    // MARK: - Helpers
    
    private var wordCount: Int {
        let words = journalText.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    private func loadBlockData() {
        guard let block = block else { return }
        title = block.title
        startTime = block.startTime
        endTime = block.endTime
        journalText = block.text
    }
    
    private func saveChanges() {
        modelData.updateBlock(
            id: blockId,
            title: title,
            startTime: startTime,
            endTime: endTime,
            text: journalText
        )
        dismiss()
    }
    
    private func deleteBlock() {
        modelData.deleteBlock(id: blockId)
        // Dismiss twice to go back to HomeView (once for edit, once for detail)
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
