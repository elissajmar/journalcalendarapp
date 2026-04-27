//
//  ModelData.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/11/26.
//

//import Foundation
//import Supabase
//
//@MainActor
//@Observable
//class ModelData {
//    var blocks: [Block] = []
//    var isLoading = false
//
//    // MARK: - Fetch
//
//    /// Fetches all blocks for the given date from Supabase,
//    /// including their sub-blocks and downloaded images.
//    func fetchBlocks(for date: Date, userId: UUID) async {
//        isLoading = true
//        defer { isLoading = false }
//
//        do {
//            let dateString = BlockDTO.dateFormatter.string(from: date)
//
//            let dtos: [BlockWithSubBlocksDTO] = try await AppSupabase.client
//                .from("blocks")
//                .select("*, sub_blocks(*)")
//                .eq("date", value: dateString)
////                .eq("user_id", value: userId.uuidString.lowercased())
//                .or("user_id.eq.\(userId.uuidString), status.neq.rejected")
//                .order("start_time")
//                .execute()
//                .value
//
////            let dtos: [BlockWithSubBlocksDTO] = try await AppSupabase.client
////                .from("blocks")
////                .select("*, sub_blocks(*)")
////                .or("user_id.eq.\(userId.uuidString), status.eq.accepted") // Adjusted logic
////                .eq("date", value: dateString)
////                .order("start_time")
////                .execute()
////                .value
//
//            var fetchedBlocks: [Block] = []
//            var seenIds = Set<UUID>()
//
//            for dto in dtos {
//                guard !seenIds.contains(dto.id) else { continue }
//                let sortedSubDTOs = dto.subBlocks.sorted { $0.sortOrder < $1.sortOrder }
//                var subBlocks: [SubBlock] = []
//
//                for subDTO in sortedSubDTOs {
//                    if subDTO.type == "images", let paths = subDTO.data.imagePaths, !paths.isEmpty {
//                        // Download images with a timeout so blocks still load if downloads stall
//                        let imageData: [Data] = await withTaskGroup(of: Data?.self, returning: [Data].self) { group in
//                            for path in paths {
//                                group.addTask {
//                                    do {
//                                        return try await withThrowingTaskGroup(of: Data.self) { inner in
//                                            inner.addTask {
//                                                try await ImageStorageService.download(path: path)
//                                            }
//                                            inner.addTask {
//                                                try await Task.sleep(for: .seconds(10))
//                                                throw CancellationError()
//                                            }
//                                            let result = try await inner.next()!
//                                            inner.cancelAll()
//                                            return result
//                                        }
//                                    } catch {
//                                        return nil
//                                    }
//                                }
//                            }
//                            var results: [Data] = []
//                            for await data in group {
//                                if let data { results.append(data) }
//                            }
//                            return results
//                        }
//                        subBlocks.append(SubBlock(dto: subDTO, imageData: imageData))
//                    } else {
//                        subBlocks.append(SubBlock(dto: subDTO))
//                    }
//                }
//
//                if let block = Block(dto: dto, subBlocks: subBlocks) {
//                    fetchedBlocks.append(block)
//                }
//                
//                if !seenIds.contains(dto.id) {
//                        let subBlocks = dto.subBlocks.map { SubBlock(dto: $0) }
//                        
//                        if var block = Block(dto: dto, subBlocks: subBlocks) {
//                            // If I am NOT the owner and I haven't accepted yet, mark as pending
//                            if dto.userId != userId && dto.status != "accepted" {
//                                block.isPending = true
//                            }
//                            
//                            fetchedBlocks.append(block)
//                            seenIds.insert(dto.id)
//                        }
//                }
//            }
//
//
//            blocks = fetchedBlocks
//        } catch {
//            print("Error fetching blocks: \(error)")
//        }
//    }
//    
//    
//    // MARK: - Create
//
//    /// Creates a new block in Supabase, uploads any images, and
//    /// adds the block to the local array.
//    func createBlock(title: String, startTime: Date, endTime: Date, subBlocks: [SubBlock], userId: UUID) async -> UUID? {
//        let calendar = Calendar.current
//        let date = calendar.startOfDay(for: startTime)
//        let blockId = UUID()
//
//        let blockDTO = BlockDTO(
//            id: blockId,
//            userId: userId,
//            title: title,
//            date: BlockDTO.dateFormatter.string(from: date),
//            startTime: BlockDTO.iso8601Formatter.string(from: startTime),
//            endTime: BlockDTO.iso8601Formatter.string(from: endTime),
//            status: "accepted"
//        )
//
//        do {
//            // Insert the block row
//            try await AppSupabase.client.from("blocks")
//                .insert(blockDTO)
//                .execute()
//
//            // Insert each sub-block, uploading images as needed
//            for (index, subBlock) in subBlocks.enumerated() {
//                var imagePaths: [String] = []
//
//                if case .images(let subId, let imageData) = subBlock {
//                    for data in imageData {
//                        let path = try await ImageStorageService.upload(
//                            imageData: data, blockId: blockId, subBlockId: subId
//                        )
//                        imagePaths.append(path)
//                    }
//                }
//
//                let dto = subBlock.toDTO(
//                    blockId: blockId, sortOrder: index, imagePaths: imagePaths
//                )
//
//                try await AppSupabase.client.from("sub_blocks")
//                    .insert(dto)
//                    .execute()
//            }
//
//            // Add to local array so the UI updates immediately
//            let newBlock = Block(
//                id: blockId, date: date, startTime: startTime,
//                endTime: endTime, title: title, subBlocks: subBlocks/*, isPending: false*/
//            )
//            blocks.append(newBlock)
//            
//            return blockId
//
//        } catch {
//            print("Error creating block: \(error)")
//            return nil
//        }
//    }
//    
//    // MARK: - Invitation Actions
//
//    func inviteUser(email: String, to blockId: UUID) async {
//        // Create the encodable object
//        let invite = EventInviteeDTO(
//            event_id: blockId,
//            invitee_email: email.lowercased().trimmingCharacters(in: .whitespaces),
//            status: "pending"
//        )
//
//        do {
//            try await AppSupabase.client
//                .from("event_invitees")
//                .insert(invite) // Swift now knows this is Encodable
//                .execute()
//            
//            print("Successfully invited \(email)")
//        } catch {
//            print("Error sending invitation: \(error)")
//        }
//    }
//    
//    // MARK: - Invitation Actions
//
//    /// Accepts an invitation by updating the block status to 'accepted'
//    func acceptInvitation(blockId: UUID) async {
//        do {
//            try await AppSupabase.client
//                .from("blocks")
//                .update(["status": "accepted"])
//                .eq("id", value: blockId.uuidString)
//                .execute()
//            
//            // Update local state so the UI reflects the change immediately
//            if let index = blocks.firstIndex(where: { $0.id == blockId }) {
//                await MainActor.run {
//                    blocks[index].isPending = false
//                }
//            }
//        } catch {
//            print("Error accepting invitation: \(error)")
//        }
//    }
//
//    /// Rejects an invitation by updating the block status to 'rejected'
//    func rejectInvitation(blockId: UUID) async {
//        do {
//            try await AppSupabase.client
//                .from("blocks")
//                .update(["status": "rejected"])
//                .eq("id", value: blockId.uuidString)
//                .execute()
//            
//            // Remove from local state since the user rejected it
//            await MainActor.run {
//                blocks.removeAll { $0.id == blockId }
//            }
//        } catch {
//            print("Error rejecting invitation: \(error)")
//        }
//    }
//
//    // MARK: - Update
//
//    /// Updates an existing block in Supabase. Replaces all sub-blocks
//    /// (deletes old ones, inserts new ones).
//    func updateBlock(id: UUID, title: String, startTime: Date, endTime: Date, subBlocks: [SubBlock], userId: UUID) async {
//        let calendar = Calendar.current
//        let date = calendar.startOfDay(for: startTime)
//
//        let blockDTO = BlockDTO(
//            id: id,
//            userId: userId,
//            title: title,
//            date: BlockDTO.dateFormatter.string(from: date),
//            startTime: BlockDTO.iso8601Formatter.string(from: startTime),
//            endTime: BlockDTO.iso8601Formatter.string(from: endTime),
//            status: "accepted"
//        )
//
//        do {
//            // Update the block row
//            try await AppSupabase.client.from("blocks")
//                .update(blockDTO)
//                .eq("id", value: id.uuidString)
//                .execute()
//
//            // Fetch old sub-blocks to find image paths to clean up
//            let oldSubDTOs: [SubBlockDTO] = try await AppSupabase.client
//                .from("sub_blocks")
//                .select()
//                .eq("block_id", value: id.uuidString)
//                .execute()
//                .value
//
//            // Collect old image paths for deletion
//            let oldImagePaths = oldSubDTOs
//                .filter { $0.type == "images" }
//                .flatMap { $0.data.imagePaths ?? [] }
//
//            // Delete old sub-block rows
//            try await AppSupabase.client.from("sub_blocks")
//                .delete()
//                .eq("block_id", value: id.uuidString)
//                .execute()
//
//            // Delete old images from Storage
//            if !oldImagePaths.isEmpty {
//                try? await ImageStorageService.delete(paths: oldImagePaths)
//            }
//
//            // Insert new sub-blocks, uploading images as needed
//            for (index, subBlock) in subBlocks.enumerated() {
//                var imagePaths: [String] = []
//
//                if case .images(let subId, let imageData) = subBlock {
//                    for data in imageData {
//                        let path = try await ImageStorageService.upload(
//                            imageData: data, blockId: id, subBlockId: subId
//                        )
//                        imagePaths.append(path)
//                    }
//                }
//
//                let dto = subBlock.toDTO(
//                    blockId: id, sortOrder: index, imagePaths: imagePaths
//                )
//
//                try await AppSupabase.client.from("sub_blocks")
//                    .insert(dto)
//                    .execute()
//            }
//
//            // Update local array
//            if let blockIndex = blocks.firstIndex(where: { $0.id == id }) {
//                blocks[blockIndex].title = title
//                blocks[blockIndex].date = date
//                blocks[blockIndex].startTime = startTime
//                blocks[blockIndex].endTime = endTime
//                blocks[blockIndex].subBlocks = subBlocks
//            }
//
//        } catch {
//            print("Error updating block: \(error)")
//        }
//    }
//
//    // MARK: - Delete
//
//    /// Deletes a block from Supabase and removes associated images
//    /// from Storage. Cascade delete handles sub-block rows.
//    func deleteBlock(id: UUID) async {
//        do {
//            // Fetch sub-blocks to find image paths
//            let subDTOs: [SubBlockDTO] = try await AppSupabase.client
//                .from("sub_blocks")
//                .select()
//                .eq("block_id", value: id.uuidString)
//                .execute()
//                .value
//
//            let imagePaths = subDTOs
//                .filter { $0.type == "images" }
//                .flatMap { $0.data.imagePaths ?? [] }
//
//            // Delete the block (cascade deletes sub-blocks)
//            try await AppSupabase.client.from("blocks")
//                .delete()
//                .eq("id", value: id.uuidString)
//                .execute()
//
//            // Delete images from Storage
//            if !imagePaths.isEmpty {
//                try? await ImageStorageService.delete(paths: imagePaths)
//            }
//
//            // Remove from local array
//            blocks.removeAll { $0.id == id }
//
//        } catch {
//            print("Error deleting block: \(error)")
//        }
//    }
//
//    // MARK: - Sample Data (for previews only)
//
//    static var sampleBlock: Block {
//        let now = Date()
//        let calendar = Calendar.current
//        let startTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now)!
//        let endTime = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: now)!
//
//        return Block(
//            date: startTime,
//            startTime: startTime,
//            endTime: endTime,
//            title: "Brunch with Uyen",
//            subBlocks: [
//                .journal(text: "Uyen and I went to brunch at this new spot downtown."),
//                .images(imageData: []),
//                .location(name: "Republique, 624 S La Brea Ave, Los Angeles, CA", latitude: 34.0625, longitude: -118.3443)
//            ]
//        )
//    }
//
//    static var sampleBlock2: Block {
//        let now = Date()
//        let calendar = Calendar.current
//        let startTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
//        let endTime = calendar.date(bySettingHour: 19, minute: 30, second: 0, of: now)!
//
//        return Block(
//            date: startTime,
//            startTime: startTime,
//            endTime: endTime,
//            title: "Dinner with roomies",
//            subBlocks: [.journal(text: "Had dinner with my roommates tonight.")]
//        )
//    }
//
//    static var sampleBlock3: Block {
//        let now = Date()
//        let calendar = Calendar.current
//        let startTime = calendar.date(bySettingHour: 10, minute: 30, second: 0, of: now)!
//        let endTime = calendar.date(bySettingHour: 11, minute: 30, second: 0, of: now)!
//
//        return Block(
//            date: startTime,
//            startTime: startTime,
//            endTime: endTime,
//            title: "Coffee with Sarah",
//            subBlocks: [.journal(text: "Quick coffee meeting with Sarah.")]
//        )
//    }
//
//    /// Creates a ModelData pre-populated with sample data (for previews).
//    static func preview() -> ModelData {
//        let data = ModelData()
//        data.blocks = [sampleBlock, sampleBlock2, sampleBlock3]
//        return data
//    }
//}

import Foundation
import Supabase

@MainActor
@Observable
class ModelData {
    var blocks: [Block] = []
    var isLoading = false

    // MARK: - Fetch

    /// Fetches all blocks for the given date from Supabase,
    /// including their sub-blocks and downloaded images.
    func fetchBlocks(for date: Date, userId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let dateString = BlockDTO.dateFormatter.string(from: date)

            // Fetches events you own OR events where you are an invitee and haven't rejected
            let dtos: [BlockWithSubBlocksDTO] = try await AppSupabase.client
                .from("blocks")
                .select("*, sub_blocks(*)")
//                .or("user_id.eq.\(userId.uuidString), status.neq.rejected")
                .eq("date", value: dateString)
                .order("start_time")
                .execute()
                .value

            var fetchedBlocks: [Block] = []
            var seenIds = Set<UUID>() // Prevents visual duplicates from overlapping RLS policies

            for dto in dtos {
                // 1. Skip if we've already processed this specific ID in this loop
                guard !seenIds.contains(dto.id) else { continue }
                seenIds.insert(dto.id)
                
                let sortedSubDTOs = dto.subBlocks.sorted { $0.sortOrder < $1.sortOrder }
                var subBlocks: [SubBlock] = []

                for subDTO in sortedSubDTOs {
                    if subDTO.type == "images", let paths = subDTO.data.imagePaths, !paths.isEmpty {
                        // Download images with a timeout
                        let imageData: [Data] = await withTaskGroup(of: Data?.self, returning: [Data].self) { group in
                            for path in paths {
                                group.addTask {
                                    do {
                                        return try await withThrowingTaskGroup(of: Data.self) { inner in
                                            inner.addTask { try await ImageStorageService.download(path: path) }
                                            inner.addTask {
                                                try await Task.sleep(for: .seconds(10))
                                                throw CancellationError()
                                            }
                                            let result = try await inner.next()!
                                            inner.cancelAll()
                                            return result
                                        }
                                    } catch { return nil }
                                }
                            }
                            var results: [Data] = []
                            for await data in group { if let data { results.append(data) } }
                            return results
                        }
                        subBlocks.append(SubBlock(dto: subDTO, imageData: imageData))
                    } else {
                        subBlocks.append(SubBlock(dto: subDTO))
                    }
                }

                // 2. Initialize the block exactly ONCE
                if var block = Block(dto: dto, subBlocks: subBlocks) {
                    // 3. Mark as pending if you are an invitee and haven't accepted yet
                    if dto.userId != userId && dto.status != "accepted" {
                        block.isPending = true
                    }
                    
                    fetchedBlocks.append(block)
//                    seenIds.insert(dto.id)
                }
            }

            // 4. Replace the entire array on the main thread
            self.blocks = fetchedBlocks
            
        } catch {
            print("Error fetching blocks: \(error)")
        }
    }
    
    // MARK: - Create

    /// Creates a new block in Supabase, uploads any images, and adds to the local array.
    func createBlock(title: String, startTime: Date, endTime: Date, subBlocks: [SubBlock], userId: UUID) async -> UUID? {
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
            status: "accepted"
        )

        do {
            try await AppSupabase.client.from("blocks").insert(blockDTO).execute()

            for (index, subBlock) in subBlocks.enumerated() {
                var imagePaths: [String] = []
                if case .images(let subId, let imageData) = subBlock {
                    for data in imageData {
                        let path = try await ImageStorageService.upload(imageData: data, blockId: blockId, subBlockId: subId)
                        imagePaths.append(path)
                    }
                }
                let dto = subBlock.toDTO(blockId: blockId, sortOrder: index, imagePaths: imagePaths)
                try await AppSupabase.client.from("sub_blocks").insert(dto).execute()
            }

            let newBlock = Block(id: blockId, date: date, startTime: startTime, endTime: endTime, title: title, subBlocks: subBlocks)
            blocks.append(newBlock)
            return blockId
        } catch {
            print("Error creating block: \(error)")
            return nil
        }
    }
    
    // MARK: - Invitation Actions

    /// Inserts a new invitation record into the event_invitees table
    func inviteUser(email: String, to blockId: UUID) async {
        let invite = EventInviteeDTO(
            event_id: blockId,
            invitee_email: email.lowercased().trimmingCharacters(in: .whitespaces),
            status: "pending"
        )

        do {
            let response = try await AppSupabase.client
                .from("event_invitees")
                .insert(invite)
                .execute()
            
            print("DEBUG: Insert status code: \(response.status)")
        } catch {
            print("DEBUG: Detailed error: \(error)")
        }
    }

    /// Accepts an invitation by updating the block status to 'accepted'
    func acceptInvitation(blockId: UUID) async {
        do {
            try await AppSupabase.client
                .from("blocks")
                .update(["status": "accepted"])
                .eq("id", value: blockId.uuidString)
                .execute()
            
            if let index = blocks.firstIndex(where: { $0.id == blockId }) {
                blocks[index].isPending = false
            }
        } catch {
            print("Error accepting invitation: \(error)")
        }
    }

    /// Rejects an invitation by updating the block status to 'rejected'
    func rejectInvitation(blockId: UUID) async {
        do {
            try await AppSupabase.client
                .from("blocks")
                .update(["status": "rejected"])
                .eq("id", value: blockId.uuidString)
                .execute()
            
            blocks.removeAll { $0.id == blockId }
        } catch {
            print("Error rejecting invitation: \(error)")
        }
    }

    // MARK: - Update

    /// Updates an existing block in Supabase and replaces all sub-blocks.
    func updateBlock(id: UUID, title: String, startTime: Date, endTime: Date, subBlocks: [SubBlock], userId: UUID) async {
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: startTime)

        let blockDTO = BlockDTO(
            id: id,
            userId: userId,
            title: title,
            date: BlockDTO.dateFormatter.string(from: date),
            startTime: BlockDTO.iso8601Formatter.string(from: startTime),
            endTime: BlockDTO.iso8601Formatter.string(from: endTime),
            status: "accepted"
        )

        do {
            try await AppSupabase.client.from("blocks")
                .update(blockDTO)
                .eq("id", value: id.uuidString)
                .execute()

            let oldSubDTOs: [SubBlockDTO] = try await AppSupabase.client
                .from("sub_blocks")
                .select()
                .eq("block_id", value: id.uuidString)
                .execute()
                .value

            let oldImagePaths = oldSubDTOs
                .filter { $0.type == "images" }
                .flatMap { $0.data.imagePaths ?? [] }

            try await AppSupabase.client.from("sub_blocks").delete().eq("block_id", value: id.uuidString).execute()

            if !oldImagePaths.isEmpty {
                try? await ImageStorageService.delete(paths: oldImagePaths)
            }

            for (index, subBlock) in subBlocks.enumerated() {
                var imagePaths: [String] = []
                if case .images(let subId, let imageData) = subBlock {
                    for data in imageData {
                        let path = try await ImageStorageService.upload(imageData: data, blockId: id, subBlockId: subId)
                        imagePaths.append(path)
                    }
                }
                let dto = subBlock.toDTO(blockId: id, sortOrder: index, imagePaths: imagePaths)
                try await AppSupabase.client.from("sub_blocks").insert(dto).execute()
            }

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

    /// Deletes a block and cleans up associated images.
    func deleteBlock(id: UUID) async {
        do {
            let subDTOs: [SubBlockDTO] = try await AppSupabase.client
                .from("sub_blocks")
                .select()
                .eq("block_id", value: id.uuidString)
                .execute()
                .value

            let imagePaths = subDTOs
                .filter { $0.type == "images" }
                .flatMap { $0.data.imagePaths ?? [] }

            try await AppSupabase.client.from("blocks").delete().eq("id", value: id.uuidString).execute()

            if !imagePaths.isEmpty {
                try? await ImageStorageService.delete(paths: imagePaths)
            }

            blocks.removeAll { $0.id == id }
        } catch {
            print("Error deleting block: \(error)")
        }
    }

//    // MARK: - Sample Data
//    static func preview() -> ModelData {
//        let data = ModelData()
//        // ... (keep your existing sampleBlock additions)
//        return data
//    }
    
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


//// MARK: - DTOs
//struct EventInviteeDTO: Encodable {
//    let event_id: UUID
//    let invitee_email: String
//    let status: String
//}
