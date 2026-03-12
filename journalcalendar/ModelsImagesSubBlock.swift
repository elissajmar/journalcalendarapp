//
//  ImagesSubBlock.swift
//  Calendar Journal
//
//  Created on 3/11/26.
//

import Foundation
import SwiftData

@Model
final class ImagesSubBlock: SubBlock {
    @Relationship(deleteRule: .cascade)
    var images: [ImageData]
    
    init(
        id: UUID = UUID(),
        images: [ImageData] = [],
        order: Int = 0
    ) {
        self.images = images
        super.init(id: id, type: .images, order: order)
    }
    
    // MARK: - Computed Properties
    
    /// Number of images in this block
    var imageCount: Int {
        images.count
    }
    
    /// Check if the block has no images
    var isEmpty: Bool {
        images.isEmpty
    }
    
    /// Display name with count (e.g., "IMAGES (3)")
    var displayNameWithCount: String {
        "IMAGES (\(imageCount))"
    }
    
    // MARK: - Helper Methods
    
    /// Add an image to the block
    func addImage(_ imageData: ImageData) {
        images.append(imageData)
    }
    
    /// Remove an image from the block
    func removeImage(_ imageData: ImageData) {
        if let index = images.firstIndex(where: { $0.id == imageData.id }) {
            images.remove(at: index)
        }
    }
    
    /// Remove image at specific index
    func removeImage(at index: Int) {
        guard index >= 0 && index < images.count else { return }
        images.remove(at: index)
    }
    
    /// Reorder images
    func moveImage(from source: IndexSet, to destination: Int) {
        images.move(fromOffsets: source, toOffset: destination)
    }
}

// MARK: - Sample Data

extension ImagesSubBlock {
    static func sampleWithThreeImages() -> ImagesSubBlock {
        let imagesBlock = ImagesSubBlock()
        
        // Add three sample images
        imagesBlock.addImage(ImageData.sample(caption: "Beautiful sunset"))
        imagesBlock.addImage(ImageData.sample(caption: "Delicious meal"))
        imagesBlock.addImage(ImageData.sample(caption: "Great atmosphere"))
        
        return imagesBlock
    }
    
    static func sampleEmpty() -> ImagesSubBlock {
        ImagesSubBlock()
    }
}
