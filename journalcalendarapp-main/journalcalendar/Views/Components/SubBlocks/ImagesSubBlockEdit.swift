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
    @State private var selectedImageData: Data?
    
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
                        .foregroundStyle(Color("TextSecondary"))
                    
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
                            .foregroundStyle(Color("TextSecondary"))
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
                            ForEach(Array(imageData.enumerated()), id: \.offset) { (index: Int, data: Data) in
                                ZStack(alignment: .topTrailing) {
                                    if let uiImage = UIImage(data: data) {
                                        Color.clear
                                            .aspectRatio(1, contentMode: .fit)
                                            .overlay {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                            }
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .onTapGesture {
                                                selectedImageData = data
                                            }
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
                                            _ = imageData.remove(at: index)
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(Color("TextPrimaryLight"))
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
                                .font(.label)
                            Text("Upload")
                                .font(.label)
                                .textCase(.uppercase)
                        }
                        .foregroundStyle(Color("TextSecondary"))
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
        .fullScreenCover(isPresented: Binding(
            get: { selectedImageData != nil },
            set: { if !$0 { selectedImageData = nil } }
        )) {
            ImageViewer(data: selectedImageData)
        }
        .transaction { transaction in
            if selectedImageData != nil {
                transaction.disablesAnimations = true
            }
        }
    }
}
