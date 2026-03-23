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
    @State private var journalText: String = ""
    @State private var isJournalExpanded: Bool = true
    @State private var isImagesExpanded: Bool = true
    
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
                VStack(alignment: .leading, spacing: 24) {
                    // Title field
                    TextField("Add title", text: $title)
                        .font(.largeTitle)
                        .fontWeight(.medium)
                        .foregroundStyle(title.isEmpty ? .secondary : .primary)
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
                                Image(systemName: "list.bullet")
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
                                    .frame(minHeight: 200)
                                    .scrollContentBackground(.hidden)
                                    .padding(12)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(8)
                                    .overlay(
                                        Group {
                                            if journalText.isEmpty {
                                                Text("Say something about the moment.")
                                                    .font(.body)
                                                    .foregroundStyle(.secondary)
                                                    .padding(.leading, 17)
                                                    .padding(.top, 20)
                                                    .allowsHitTesting(false)
                                            }
                                        },
                                        alignment: .topLeading
                                    )
                                
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
                                Image(systemName: "list.bullet")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text("IMAGES")
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
                    
                    // Add sub-blocks button placeholder
                    Button {
                        // TODO: Implement add sub-blocks
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                                .font(.body)
                            Text("Add sub-blocks")
                                .font(.body)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brown)
                        .cornerRadius(8)
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
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            // TODO: Implement delete/cancel
                            dismiss()
                        } label: {
                            Image(systemName: "trash")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.brown)
                            .foregroundStyle(.white)
                            .cornerRadius(8)
                        }
                        .disabled(title.isEmpty)
                        .opacity(title.isEmpty ? 0.5 : 1.0)
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var wordCount: Int {
        let words = journalText.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    private func createBlock() {
        modelData.createBlock(
            title: title,
            startTime: startTime,
            endTime: endTime,
            text: journalText
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
