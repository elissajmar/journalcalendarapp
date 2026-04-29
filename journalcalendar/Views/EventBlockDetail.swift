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
    @Environment(CalendarService.self) var calendarService
    @Environment(\.dismiss) var dismiss
    var blockId: UUID
    
    @State private var showDeleteAlert = false
    @State private var inviteEmail = ""
    @State private var isInviting = false
    @State private var showRecurringDeleteDialog = false
    
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
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(timeRangeString(for: block))
                                .labelStyle()

                            if block.recurrence != .never {
                                Text("Repeats \(block.recurrence.displayName)")
                                    .labelStyle()
                            }
                        }
                        
                        // Sub-blocks
                        ForEach(block.subBlocks) { subBlock in
                            Group {
                                switch subBlock {
                                case .journal(_, let text):
                                    JournalSubBlockDetail(text: text)
                                case .images(_, let imageData):
                                    ImagesSubBlockDetail(imageData: imageData)
                                case .link(_, let url):
                                    LinkSubBlockDetail(url: url)
                                case .location(_, let name, let latitude, let longitude):
                                    LocationSubBlockDetail(name: name, latitude: latitude, longitude: longitude)
                                case .invite:
                                    EmptyView()
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if block.isPending {
                            HStack(spacing: 20) {
                                Button(action: {
                                    Task { await modelData.acceptInvitation(blockId: block.id) }
                                }) {
                                    Text("Accept")
                                        .fontWeight(.bold)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }

                                Button(action: {
                                    Task { await modelData.rejectInvitation(blockId: block.id) }
                                }) {
                                    Text("Reject")
                                        .fontWeight(.bold)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.top, 24)
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
                                if block.recurrence != .never {
                                    showRecurringDeleteDialog = true
                                } else {
                                    showDeleteAlert = true
                                }
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

    private func deleteThisInstance() {
        guard let block = block else { return }
        Task {
            await modelData.deleteBlockInstance(id: blockId, date: block.date)
        }
        dismiss()
    }

    private func deleteThisAndFuture() {
        guard let block = block else { return }
        Task {
            await modelData.deleteBlockAndFuture(id: blockId, fromDate: block.date)
        }
        dismiss()
    }
}


#Preview {
    @Previewable @State var showSheet = true
    
    // 1. Initialize your dependencies
    let modelData = ModelData.preview()
    let authController = AuthController()
    let calendarService = CalendarService()
    
    // 2. Simply list the view (no 'return' keyword)
    Color.clear
        .sheet(isPresented: $showSheet) {
            EventBlockDetail(blockId: ModelData.sampleBlock.id)
                .environment(modelData)
                .environment(authController)
                .environment(calendarService)
        }
        .onAppear {
            showSheet = true
        }
}
