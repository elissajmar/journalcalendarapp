//
//  EventBlockDetail.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/11/26.
//

import SwiftUI

struct EventBlockDetail: View {
    @Environment(ModelData.self) var modelData
    @Environment(AuthController.self) var auth
    @Environment(\.dismiss) var dismiss
    var blockId: UUID
    
    @State private var showDeleteAlert = false
    
    private var block: Block? {
        modelData.blocks.first(where: { $0.id == blockId })
    }

    var body: some View {
        NavigationStack {
            if let block = block {
                ScrollView {
                    VStack(alignment: .leading, spacing: 48) {
                        // Title and time
                        VStack(alignment: .leading, spacing: 12) {
                            Text(block.title)
                                .heading3Style()
                                .lineLimit(nil)
                            
                            Text(timeRangeString(for: block))
                                .labelStyle()
                        }
                        
                        // Sub-blocks
                        ForEach(block.subBlocks) { subBlock in
                            switch subBlock {
                            case .journal(_, let text):
                                JournalSubBlockDetail(text: text)
                            case .images(_, let imageData):
                                ImagesSubBlockDetail(imageData: imageData)
                            case .link(_, let url):
                                LinkSubBlockDetail(url: url)
                            case .location(_, let name, let latitude, let longitude):
                                LocationSubBlockDetail(name: name, latitude: latitude, longitude: longitude)
                            }
                        }
                    }
                    .padding()
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
                                .foregroundStyle(Color("TextSecondary"))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            NavigationLink {
                                EventBlockDetailEdit(blockId: blockId)
                                    .environment(modelData)
                                    .environment(auth)
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
                    .paragraph1Style()
                    .foregroundStyle(Color("TextSecondary"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.body)
                                    .foregroundStyle(Color("TextSecondary"))
                            }
                            .buttonStyle(.plain)
                        }
                    }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func timeRangeString(for block: Block) -> String {
        DateFormatters.timeRange(from: block.startTime, to: block.endTime)
    }
    
    private func deleteBlock() {
        Task {
            await modelData.deleteBlock(id: blockId)
        }
        dismiss()
    }
}

#Preview {
    @Previewable @State var showSheet = true
    let modelData = ModelData.preview()
    
    return Color.clear
        .sheet(isPresented: $showSheet) {
            EventBlockDetail(blockId: ModelData.sampleBlock.id)
                .environment(modelData)
        }
        .onAppear {
            showSheet = true
        }
}
