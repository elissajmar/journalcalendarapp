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
            let userIdString = userId.uuidString.lowercased()

            // Fetch blocks for the exact date
            let exactDtos: [BlockWithSubBlocksDTO] = try await AppSupabase.client
                .from("blocks")
                .select("*, sub_blocks(*)")
                .eq("date", value: dateString)
                .eq("user_id", value: userIdString)
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
            // Fetch recurring blocks from earlier dates
            let recurringDtos: [BlockWithSubBlocksDTO] = try await AppSupabase.client
                .from("blocks")
                .select("*, sub_blocks(*)")
                .lt("date", value: dateString)
                .neq("recurrence", value: "never")
                .eq("user_id", value: userIdString)
                .order("start_time")
                .execute()
                .value

            // Filter recurring blocks that match the selected date
            let matchingRecurring = recurringDtos.filter { dto in
                guard let originDate = BlockDTO.dateFormatter.date(from: dto.date) else { return false }
                let recurrence = Recurrence(rawValue: dto.recurrence ?? "never") ?? .never
                let recurrenceEnd = dto.recurrenceEnd.flatMap { BlockDTO.dateFormatter.date(from: $0) }
                return Self.recurrenceMatches(recurrence, originDate: originDate, targetDate: date, exceptions: dto.exceptions ?? [], recurrenceEnd: recurrenceEnd)
            }

            // Combine, deduplicating by id
            let allDtos = exactDtos + matchingRecurring
            var seenIds = Set<UUID>()
            var fetchedBlocks: [Block] = []
            let targetDateString = BlockDTO.dateFormatter.string(from: date)

            for dto in allDtos {
                guard seenIds.insert(dto.id).inserted else { continue }

                // Skip if this date is in the block's exceptions list
                if (dto.exceptions ?? []).contains(targetDateString) {
                    continue
                }

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

                if var block = Block(dto: dto, subBlocks: subBlocks) {
                    // Adjust recurring blocks' times to the target date
                    if !Calendar.current.isDate(block.startTime, inSameDayAs: date) {
                        block = Self.adjustBlockToDate(block, targetDate: date)
                    }
                    fetchedBlocks.append(block)
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

    // MARK: - Recurrence Matching

    /// Checks whether a block with the given recurrence and origin date
    /// should appear on the target date.
    private static func recurrenceMatches(_ recurrence: Recurrence, originDate: Date, targetDate: Date, exceptions: [String] = [], recurrenceEnd: Date? = nil) -> Bool {
        let calendar = Calendar.current
        guard targetDate >= originDate else { return false }

        // Check if target date is past the recurrence end
        if let endDate = recurrenceEnd, calendar.startOfDay(for: targetDate) > calendar.startOfDay(for: endDate) {
            return false
        }

        // Check if target date is in exceptions
        let targetDateString = BlockDTO.dateFormatter.string(from: targetDate)
        if exceptions.contains(targetDateString) {
            return false
        }

        switch recurrence {
        case .never:
            return false
        case .daily:
            return true
        case .weekly:
            return calendar.component(.weekday, from: originDate) == calendar.component(.weekday, from: targetDate)
        case .monthly:
            return calendar.component(.day, from: originDate) == calendar.component(.day, from: targetDate)
        case .yearly:
            return calendar.component(.day, from: originDate) == calendar.component(.day, from: targetDate)
                && calendar.component(.month, from: originDate) == calendar.component(.month, from: targetDate)
        }
    }

    /// Returns a copy of the block with startTime, endTime, and date
    /// shifted to the target date while keeping the original time-of-day.
    private static func adjustBlockToDate(_ block: Block, targetDate: Date) -> Block {
        let calendar = Calendar.current
        let startComps = calendar.dateComponents([.hour, .minute, .second], from: block.startTime)
        let endComps = calendar.dateComponents([.hour, .minute, .second], from: block.endTime)

        let newStart = calendar.date(bySettingHour: startComps.hour ?? 0,
                                     minute: startComps.minute ?? 0,
                                     second: startComps.second ?? 0,
                                     of: targetDate) ?? block.startTime
        let newEnd = calendar.date(bySettingHour: endComps.hour ?? 0,
                                   minute: endComps.minute ?? 0,
                                   second: endComps.second ?? 0,
                                   of: targetDate) ?? block.endTime

        return Block(
            id: block.id,
            date: calendar.startOfDay(for: targetDate),
            startTime: newStart,
            endTime: newEnd,
            title: block.title,
            recurrence: block.recurrence,
            subBlocks: block.subBlocks,
            originalDate: block.originalDate,
            exceptions: block.exceptions,
            recurrenceEnd: block.recurrenceEnd
        )
    }

    // MARK: - Create

    /// Creates a new block in Supabase, uploads any images, and
    /// adds the block to the local array.
    func createBlock(title: String, startTime: Date, endTime: Date, recurrence: Recurrence = .never, subBlocks: [SubBlock], userId: UUID) async {
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: startTime)
        let blockId = UUID()

        let blockDTO = BlockDTO(
            id: blockId,
            userId: userId,
            title: title,
            date: BlockDTO.dateFormatter.string(from: date),
            startTime: BlockDTO.iso8601Formatter.string(from: startTime),
            endTime: BlockDTO.iso8601Formatter.string(from: endTime),
            recurrence: recurrence.rawValue,
            exceptions: nil,
            recurrenceEnd: nil
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
                endTime: endTime, title: title, recurrence: recurrence, subBlocks: subBlocks
            )
            blocks.append(newBlock)

        } catch {
            print("Error creating block: \(error)")
        }
    }

    // MARK: - Update

    /// Updates an existing block in Supabase. Replaces all sub-blocks
    /// (deletes old ones, inserts new ones).
    func updateBlock(id: UUID, title: String, startTime: Date, endTime: Date, recurrence: Recurrence = .never, subBlocks: [SubBlock], userId: UUID) async {
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: startTime)

        let blockDTO = BlockDTO(
            id: id,
            userId: userId,
            title: title,
            date: BlockDTO.dateFormatter.string(from: date),
            startTime: BlockDTO.iso8601Formatter.string(from: startTime),
            endTime: BlockDTO.iso8601Formatter.string(from: endTime),
            recurrence: recurrence.rawValue,
            exceptions: nil,
            recurrenceEnd: nil
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
                blocks[blockIndex].recurrence = recurrence
                blocks[blockIndex].subBlocks = subBlocks
            }

        } catch {
            print("Error updating block: \(error)")
        }
    }

    // MARK: - Delete

    /// Helper structs for partial Supabase updates.
    private struct ExceptionsUpdate: Codable {
        let exceptions: [String]
    }

    private struct RecurrenceEndUpdate: Codable {
        let recurrenceEnd: String

        enum CodingKeys: String, CodingKey {
            case recurrenceEnd = "recurrence_end"
        }
    }

    /// Deletes a single instance of a recurring block by adding
    /// the date to the exceptions list.
    func deleteBlockInstance(id: UUID, date: Date) async {
        do {
            // Fetch current block to get existing exceptions
            let blockDTOs: [BlockWithSubBlocksDTO] = try await AppSupabase.client
                .from("blocks")
                .select("*, sub_blocks(*)")
                .eq("id", value: id.uuidString)
                .execute()
                .value

            guard let dto = blockDTOs.first else { return }

            var exceptions = dto.exceptions ?? []
            let dateString = BlockDTO.dateFormatter.string(from: date)
            if !exceptions.contains(dateString) {
                exceptions.append(dateString)
            }

            try await AppSupabase.client.from("blocks")
                .update(ExceptionsUpdate(exceptions: exceptions))
                .eq("id", value: id.uuidString)
                .execute()

            // Remove from local array so UI updates immediately
            blocks.removeAll { $0.id == id }
        } catch {
            print("Error adding exception to block: \(error)")
        }
    }

    /// Deletes this instance and all future instances of a recurring block.
    /// If the date is the origin date, deletes the entire block.
    /// Otherwise, sets the recurrence end to the day before the given date.
    func deleteBlockAndFuture(id: UUID, fromDate: Date) async {
        do {
            // Fetch the original block to check if this is the origin date
            let blockDTOs: [BlockWithSubBlocksDTO] = try await AppSupabase.client
                .from("blocks")
                .select("*, sub_blocks(*)")
                .eq("id", value: id.uuidString)
                .execute()
                .value

            guard let dto = blockDTOs.first,
                  let originDate = BlockDTO.dateFormatter.date(from: dto.date) else { return }

            let calendar = Calendar.current
            if calendar.isDate(originDate, inSameDayAs: fromDate) {
                // Deleting from the origin date means delete everything
                await deleteBlock(id: id)
            } else {
                // Set recurrence end to the day before fromDate
                guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: fromDate)) else { return }
                let endDateString = BlockDTO.dateFormatter.string(from: dayBefore)

                try await AppSupabase.client.from("blocks")
                    .update(RecurrenceEndUpdate(recurrenceEnd: endDateString))
                    .eq("id", value: id.uuidString)
                    .execute()

                // Remove from local array
                blocks.removeAll { $0.id == id }
            }
        } catch {
            print("Error ending recurrence: \(error)")
        }
    }

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
