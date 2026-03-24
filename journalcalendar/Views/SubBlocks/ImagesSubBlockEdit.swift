//
//  ImagesSubBlockEdit.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/23/26.
//

import SwiftUI
import PhotosUI

struct ImagesSubBlockEdit: View {
    @Binding var imageData: [Data]
    @Binding var isExpanded: Bool
    var onRemove: () -> Void
    
    @State private var selectedItems: [PhotosPickerItem] = []
    
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
                    
                    Text("IMAGES (\(imageData.count))")
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
                    if !imageData.isEmpty {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(Array(imageData.enumerated()), id: \.offset) { index, data in
                                ZStack(alignment: .topTrailing) {
                                    if let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .aspectRatio(1, contentMode: .fill)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.3))
                                            .aspectRatio(1, contentMode: .fit)
                                            .overlay {
                                                Image(systemName: "exclamationmark.triangle")
                                                    .foregroundStyle(.gray)
                                            }
                                    }
                                    
                                    // Delete button per image
                                    Button {
                                        withAnimation {
                                            imageData.remove(at: index)
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                            .shadow(radius: 2)
                                    }
                                    .offset(x: -4, y: 4)
                                }
                            }
                        }
                    }
                    
                    // Photo picker
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "arrow.up.circle")
                                .font(.body)
                            Text("Upload")
                                .font(.body)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .onChange(of: selectedItems) { _, newItems in
                        Task {
                            for item in newItems {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data),
                                   let jpeg = uiImage.jpegData(compressionQuality: 0.8) {
                                    imageData.append(jpeg)
                                }
                            }
                            selectedItems.removeAll()
                        }
                    }
                }
            }
        }
    }
}
