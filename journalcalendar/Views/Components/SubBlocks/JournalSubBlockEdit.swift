//
//  JournalSubBlockEdit.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/23/26.
//

import SwiftUI

struct JournalSubBlockEdit: View {
    @Binding var text: String
    @Binding var isExpanded: Bool
    var onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "book")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("JOURNAL")
                        .labelStyle()
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            onRemove()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $text)
                        .font(.paragraph1)
                        .lineSpacing(4)
                        .frame(minHeight: 200)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(8)
                        .overlay(
                            Group {
                                if text.isEmpty {
                                    Text("Say something about the moment.")
                                        .font(.paragraph1)
                                        .foregroundStyle(.secondary)
                                        .padding(.leading, 17)
                                        .padding(.top, 20)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                    
                    Text("\(wordCount) words")
                        .labelStyle()
                }
            }
        }
    }
    
    private var wordCount: Int {
        text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
    }
}
