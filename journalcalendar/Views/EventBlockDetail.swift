//
//  EventBlockDetail.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/11/26.
//

import SwiftUI

struct EventBlockDetail: View {
    @Environment(ModelData.self) var modelData
    @Environment(\.dismiss) var dismiss
    var blockId: UUID
    
    @State private var showDeleteAlert = false
    
    private var block: Block? {
        modelData.blocks.first(where: { $0.id == blockId })
    }

    var body: some View {
        NavigationStack {
            if let block = block {
                VStack(alignment: .leading, spacing: 0) {
                    // Title and time - Fixed at top
                    VStack(alignment: .leading, spacing: 8) {
                        Text(block.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .lineLimit(nil)
                        
                        Text(timeRangeString(for: block))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    // Scrollable content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Journal section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("JOURNAL")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                
                                Text(block.text)
                                    .font(.body)
                                    .lineSpacing(4)
                            }
                            
                            // Images section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("IMAGES")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                
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
                            }
                        }
                        .padding()
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
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
                            Image(systemName: "xmark")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            NavigationLink {
                                EventBlockDetailEdit(blockId: blockId)
                                    .environment(modelData)
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.body)
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                showDeleteAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.body)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else {
                Text("Block not found")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func timeRangeString(for block: Block) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        
        let start = formatter.string(from: block.startTime).uppercased()
        let end = formatter.string(from: block.endTime).uppercased()
        
        return "\(start) - \(end)"
    }
    
    private func deleteBlock() {
        modelData.deleteBlock(id: blockId)
        dismiss()
    }
}

#Preview {
    @Previewable @State var showSheet = true
    let modelData = ModelData()
    
    return Color.clear
        .sheet(isPresented: $showSheet) {
            EventBlockDetail(blockId: ModelData.sampleBlock.id)
                .environment(modelData)
        }
        .onAppear {
            showSheet = true
        }
}
