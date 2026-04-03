//
//  LinkSubBlockEdit.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/23/26.
//

import SwiftUI

struct LinkSubBlockEdit: View {
    @Binding var url: String
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
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("LINK")
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
                TextField("https://", text: $url)
                    .font(.paragraph1)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(8)
            }
        }
    }
}
