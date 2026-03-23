//
//  ImagesSubBlockEdit.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/23/26.
//

import SwiftUI

struct ImagesSubBlockEdit: View {
    @Binding var imageNames: [String]
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
                    Image(systemName: "photo.on.rectangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("IMAGES (\(imageNames.count))")
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
                VStack(alignment: .leading, spacing: 12) {
                    if !imageNames.isEmpty {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(imageNames, id: \.self) { _ in
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
    }
}
