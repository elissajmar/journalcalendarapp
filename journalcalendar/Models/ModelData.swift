//
//  ModelData.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/11/26.
//

import Foundation
import Supabase

@MainActor
@Observable
class ModelData {
    var blocks: [Block] = []
    var isLoading = false

    // MARK: - Fetch

    /// Fetches all blocks for a single date.
    func fetchBlocks(for date: Date, userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let dateString = BlockDTO.dateFormatter.string(from: date)
            let dtos: [BlockWithSubBlocksDTO] = try await AppSupabase.client
                .from("blocks")
                .select("*, sub_blocks(*)")
                .eq("date", value: dateString)
                .eq("user_id", value: userId.uuidString.lowercased())
                .order("start_time")
                .execute()
                .value
            blocks = await processBlockDTOs(dtos)
        } catch {
            print("Error fetching blocks: \(error)")
        }
    }

    /// Fetches all blocks across multiple dates (e.g. for the 3-day view).
    func fetchBlocks(for dates: [Date], userId: UUID) async {
        guard !dates.isEmpty else { blocks = []; return }
        isLoading = true
        defer { isLoading = false }
        do {
            let dateStrings = dates.map { BlockDTO.dateFormatter.string(from: $0) }
            let dtos: [BlockWithSubBlocksDTO] = try await AppSupabase.client
                .from("blocks")
                .select("*, sub_blocks(*)")
                .in("date", value: dateStrings)
                .eq("user_id", value: userId.uuidString.lowercased())
                .order("start_time")
                .execute()
                .value
            blocks = await processBlockDTOs(dtos)
        } catch {
            print("Error fetching blocks for multiple dates: \(error)")
        }
    }

    /// Converts raw joined DTOs into fully hydrated Block values,
    /// downloading any image sub-block data along the way.
    private func processBlockDTOs(_ dtos: [BlockWithSubBlocksDTO]) async -> [Block] {
        var fetchedBlocks: [Block] = []
        for dto in dtos {
            let sortedSubDTOs = dto.subBlocks.sorted { $0.sortOrder < $1.sortOrder }
            var subBlocks: [SubBlock] = []
            for subDTO in sortedSubDTOs {
                if subDTO.type == "images", let paths = subDTO.data.imagePaths, !paths.isEmpty {
                    let imageData: [Data] = await withTaskGroup(of: Data?.self, returning: [Data].self) { group in
                        for path in paths {
                            group.addTask {
                                do {
                                    return try await withThrowingTaskGroup(of: Data.self) { inner in
                                        inner.addTask {
                                            try await ImageStorageService.download(path: path)
                                        }
                                        inner.addTask {
                                            try await Task.sleep(for: .seconds(10))
                                            throw CancellationError()
                                        }
                                        let result = try await inner.next()!
                                        inner.cancelAll()
                                        return result
                                    }
                                } catch {
                                    return nil
                                }
                            }
                        }
                        var results: [Data] = []
                        for await data in group {
                            if let data { results.append(data) }
                        }
                        return results
                    }
                    subBlocks.append(SubBlock(dto: subDTO, imageData: imageData))
                } else {
                    subBlocks.append(SubBlock(dto: subDTO))
                }
            }
            if let block = Block(dto: dto, subBlocks: subBlocks) {
                fetchedBlocks.append(block)
            }
        }
        return fetchedBlocks
    }

    /// Fetches all blocks in a date range (inclusive). Used by the monthly view.
    /// Skips image downloads since only titles are needed.
    func fetchBlocks(from startDate: Date, to endDate: Date, userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let start = BlockDTO.dateFormatter.string(from: startDate)
            let end = BlockDTO.dateFormatter.string(from: endDate)
            let dtos: [BlockWithSubBlocksDTO] = try await AppSupabase.client
                .from("blocks")
                .select("*, sub_blocks(*)")
                .gte("date", value: start)
                .lte("date", value: end)
                .eq("user_id", value: userId.uuidString.lowercased())
                .order("start_time")
                .execute()
                .value
            var fetched: [Block] = []
            for dto in dtos {
                let sortedSubDTOs = dto.subBlocks.sorted { $0.sortOrder < $1.sortOrder }
                let subBlocks = sortedSubDTOs.map { SubBlock(dto: $0) }
                if let block = Block(dto: dto, subBlocks: subBlocks) {
                    fetched.append(block)
                }
            }
            blocks = fetched
        } catch {
            print("Error fetching blocks for range: \(error)")
        }
    }

    // MARK: - Create

    /// Creates a new block in Supabase, uploads any images, and
    /// adds the block to the local array.
    func createBlock(title: String, startTime: Date, endTime: Date, subBlocks: [SubBlock], userId: UUID) async {
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: startTime)
        let blockId = UUID()

        let blockDTO = BlockDTO(
            id: blockId,
            userId: userId,
            title: title,
            date: BlockDTO.dateFormatter.string(from: date),
            startTime: BlockDTO.iso8601Formatter.string(from: startTime),
            endTime: BlockDTO.iso8601Formatter.string(from: endTime)
        )

        do {
            // Insert the block row
            try await AppSupabase.client.from("blocks")
                .insert(blockDTO)
                .execute()

            // Insert each sub-block, uploading images as needed
            for (index, subBlock) in subBlocks.enumerated() {
                var imagePaths: [String] = []

                if case .images(let subId, let imageData) = subBlock {
                    for data in imageData {
                        let path = try await ImageStorageService.upload(
                            imageData: data, blockId: blockId, subBlockId: subId
                        )
                        imagePaths.append(path)
                    }
                }

                let dto = subBlock.toDTO(
                    blockId: blockId, sortOrder: index, imagePaths: imagePaths
                )

                try await AppSupabase.client.from("sub_blocks")
                    .insert(dto)
                    .execute()
            }

            // Add to local array so the UI updates immediately
            let newBlock = Block(
                id: blockId, date: date, startTime: startTime,
                endTime: endTime, title: title, subBlocks: subBlocks
            )
            blocks.append(newBlock)

        } catch {
            print("Error creating block: \(error)")
        }
    }

    // MARK: - Update

    /// Updates an existing block in Supabase. Replaces all sub-blocks
    /// (deletes old ones, inserts new ones).
    func updateBlock(id: UUID, title: String, startTime: Date, endTime: Date, subBlocks: [SubBlock], userId: UUID) async {
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: startTime)

        let blockDTO = BlockDTO(
            id: id,
            userId: userId,
            title: title,
            date: BlockDTO.dateFormatter.string(from: date),
            startTime: BlockDTO.iso8601Formatter.string(from: startTime),
            endTime: BlockDTO.iso8601Formatter.string(from: endTime)
        )

        do {
            // Update the block row
            try await AppSupabase.client.from("blocks")
                .update(blockDTO)
                .eq("id", value: id.uuidString)
                .execute()

            // Fetch old sub-blocks to find image paths to clean up
            let oldSubDTOs: [SubBlockDTO] = try await AppSupabase.client
                .from("sub_blocks")
                .select()
                .eq("block_id", value: id.uuidString)
                .execute()
                .value

            // Collect old image paths for deletion
            let oldImagePaths = oldSubDTOs
                .filter { $0.type == "images" }
                .flatMap { $0.data.imagePaths ?? [] }

            // Delete old sub-block rows
            try await AppSupabase.client.from("sub_blocks")
                .delete()
                .eq("block_id", value: id.uuidString)
                .execute()

            // Delete old images from Storage
            if !oldImagePaths.isEmpty {
                try? await ImageStorageService.delete(paths: oldImagePaths)
            }

            // Insert new sub-blocks, uploading images as needed
            for (index, subBlock) in subBlocks.enumerated() {
                var imagePaths: [String] = []

                if case .images(let subId, let imageData) = subBlock {
                    for data in imageData {
                        let path = try await ImageStorageService.upload(
                            imageData: data, blockId: id, subBlockId: subId
                        )
                        imagePaths.append(path)
                    }
                }

                let dto = subBlock.toDTO(
                    blockId: id, sortOrder: index, imagePaths: imagePaths
                )

                try await AppSupabase.client.from("sub_blocks")
                    .insert(dto)
                    .execute()
            }

            // Update local array
            if let blockIndex = blocks.firstIndex(where: { $0.id == id }) {
                blocks[blockIndex].title = title
                blocks[blockIndex].date = date
                blocks[blockIndex].startTime = startTime
                blocks[blockIndex].endTime = endTime
                blocks[blockIndex].subBlocks = subBlocks
            }

        } catch {
            print("Error updating block: \(error)")
        }
    }

    // MARK: - Delete

    /// Deletes a block from Supabase and removes associated images
    /// from Storage. Cascade delete handles sub-block rows.
    func deleteBlock(id: UUID) async {
        do {
            // Fetch sub-blocks to find image paths
            let subDTOs: [SubBlockDTO] = try await AppSupabase.client
                .from("sub_blocks")
                .select()
                .eq("block_id", value: id.uuidString)
                .execute()
                .value

            let imagePaths = subDTOs
                .filter { $0.type == "images" }
                .flatMap { $0.data.imagePaths ?? [] }

            // Delete the block (cascade deletes sub-blocks)
            try await AppSupabase.client.from("blocks")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()

            // Delete images from Storage
            if !imagePaths.isEmpty {
                try? await ImageStorageService.delete(paths: imagePaths)
            }

            // Remove from local array
            blocks.removeAll { $0.id == id }

        } catch {
            print("Error deleting block: \(error)")
        }
    }

    // MARK: - Sample Data (for previews only)

    static var sampleBlock: Block {
        let now = Date()
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now)!
        let endTime = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: now)!

        return Block(
            date: startTime,
            startTime: startTime,
            endTime: endTime,
            title: "Brunch with Uyen",
            subBlocks: [
                .journal(text: "Uyen and I went to brunch at this new spot downtown."),
                .images(imageData: []),
                .location(name: "Republique, 624 S La Brea Ave, Los Angeles, CA", latitude: 34.0625, longitude: -118.3443)
            ]
        )
    }

    static var sampleBlock2: Block {
        let now = Date()
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
        let endTime = calendar.date(bySettingHour: 19, minute: 30, second: 0, of: now)!

        return Block(
            date: startTime,
            startTime: startTime,
            endTime: endTime,
            title: "Dinner with roomies",
            subBlocks: [.journal(text: "Had dinner with my roommates tonight.")]
        )
    }

    static var sampleBlock3: Block {
        let now = Date()
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: 10, minute: 30, second: 0, of: now)!
        let endTime = calendar.date(bySettingHour: 11, minute: 30, second: 0, of: now)!

        return Block(
            date: startTime,
            startTime: startTime,
            endTime: endTime,
            title: "Coffee with Sarah",
            subBlocks: [.journal(text: "Quick coffee meeting with Sarah.")]
        )
    }

    /// Creates a ModelData pre-populated with sample data (for previews).
    static func preview() -> ModelData {
        let data = ModelData()
        data.blocks = [sampleBlock, sampleBlock2, sampleBlock3]
        return data
    }
}
