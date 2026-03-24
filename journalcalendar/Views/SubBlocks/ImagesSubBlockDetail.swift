//
//  ImagesSubBlockDetail.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/23/26.
//

import SwiftUI

struct ImagesSubBlockDetail: View {
    let imageData: [Data]
    
    @State private var selectedImageData: Data?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("IMAGES")
                .labelStyle()
            
            if !imageData.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(Array(imageData.enumerated()), id: \.offset) { _, data in
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
                        }
                    }
                }
            } else {
                Text("No images")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { selectedImageData != nil },
            set: { if !$0 { selectedImageData = nil } }
        )) {
            ImageViewer(data: selectedImageData)
        }
    }
}
