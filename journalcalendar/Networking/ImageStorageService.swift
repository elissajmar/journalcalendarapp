//
//  ImageStorageService.swift
//  journalcalendar
//
//  Handles uploading, downloading, and deleting images
//  from Supabase Storage. Includes an in-memory cache
//  to avoid re-downloading the same image.
//

import Foundation
import Supabase

struct ImageStorageService {

    /// In-memory cache for downloaded images.
    private static let cache = NSCache<NSString, NSData>()

    // MARK: - Upload

    /// Uploads JPEG data to Supabase Storage and returns the storage path.
    static func upload(
        imageData: Data,
        blockId: UUID,
        subBlockId: UUID
    ) async throws -> String {
        let fileName = "\(UUID().uuidString).jpg"
        let path = "\(blockId)/\(subBlockId)/\(fileName)"

        try await AppSupabase.client.storage
            .from("images")
            .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg"))

        return path
    }

    // MARK: - Download

    /// Downloads image data from the given storage path, using cache when available.
    static func download(path: String) async throws -> Data {
        if let cached = cache.object(forKey: path as NSString) {
            return cached as Data
        }

        let data = try await AppSupabase.client.storage
            .from("images")
            .download(path: path)

        cache.setObject(data as NSData, forKey: path as NSString)
        return data
    }

    // MARK: - Delete

    /// Removes images at the given storage paths.
    static func delete(paths: [String]) async throws {
        guard !paths.isEmpty else { return }
        _ = try await AppSupabase.client.storage
            .from("images")
            .remove(paths: paths)

        for path in paths {
            cache.removeObject(forKey: path as NSString)
        }
    }
}
