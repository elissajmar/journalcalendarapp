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

    /// Fetches all blocks for a single date, including recurring blocks.
    func fetchBlocks(for date: Date, userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let dateString = BlockDTO.dateFormatter.string(from: date)
            let userIdString = userId.uuidString.lowercased()

            // Fetch owned blocks for the exact date
            let exactDtos: [BlockWithSubBlocksDTO] = try await AppSupabase.client
                .from("blocks")
                .select("*, sub_blocks(*)")
                .eq("date", value: dateString)
                .eq("user_id", value: userIdString)
                .order("start_time")
                .execute()
                .value

            // Fetch owned recurring blocks from earlier dates
            let recurringDtos: [BlockWithSubBlocksDTO] = try await AppSupabase.client
                .from("blocks")
                .select("*, sub_blocks(*)")
                .lt("date", value: dateString)
                .neq("recurrence", value: "never")
                .eq("user_id", value: userIdString)
                .order("start_time")
                .execute()
                .value

            // Fetch invited blocks for this date
            let inviteStatuses = await fetchInviteStatuses(userId: userId)
            var invitedDtos: [BlockWithSubBlocksDTO] = []
            if !inviteStatuses.isEmpty {
                invitedDtos = try await AppSupabase.client
                    .from("blocks")
                    .select("*, sub_blocks(*)")
                    .eq("date", value: dateString)
                    .in("id", value: Array(inviteStatuses.keys).map { $0.uuidString.lowercased() })
                    .order("start_time")
                    .execute()
                    .value
            }

            // Filter recurring blocks that match the selected date
            let matchingRecurring = recurringDtos.filter { dto in
                guard let originDate = BlockDTO.dateFormatter.date(from: dto.date) else { return false }
                let recurrence = Recurrence(rawValue: dto.recurrence ?? "never") ?? .never
                let recurrenceEnd = dto.recurrenceEnd.flatMap { BlockDTO.dateFormatter.date(from: $0) }
                return Self.recurrenceMatches(recurrence, originDate: originDate, targetDate: date, exceptions: dto.exceptions ?? [], recurrenceEnd: recurrenceEnd)
            }

            // Combine owned + recurring + invited, deduplicating by id
            let allDtos = exactDtos + matchingRecurring + invitedDtos
            var seenIds = Set<UUID>()
            let targetDateString = BlockDTO.dateFormatter.string(from: date)
            var uniqueDtos: [BlockWithSubBlocksDTO] = []

            for dto in allDtos {
                guard seenIds.insert(dto.id).inserted else { continue }
                if (dto.exceptions ?? []).contains(targetDateString) {
                    continue
                }
                uniqueDtos.append(dto)
            }

            var fetchedBlocks = await processBlockDTOs(uniqueDtos)

            // Adjust recurring blocks' times to the target date
            fetchedBlocks = fetchedBlocks.map { block in
                if !Calendar.current.isDate(block.startTime, inSameDayAs: date) {
                    return Self.adjustBlockToDate(block, targetDate: date)
                }
                return block
            }

            // Mark invited blocks as pending
            let pendingIds = Set(inviteStatuses.filter { $0.value == "pending" }.map { $0.key })
            markPendingBlocks(&fetchedBlocks, pendingIds: pendingIds)

            print("DEBUG: fetchedBlocks count=\(fetchedBlocks.count)")
            blocks = fetchedBlocks
        } catch {
            print("DEBUG ERROR fetching blocks: \(error)")
        }
    }

    /// Fetches all blocks across multiple dates (e.g. for the 3-day and monthly views),
    /// including recurring blocks that fall on those dates.
    func fetchBlocks(for dates: [Date], userId: UUID) async {
        guard !dates.isEmpty else { blocks = []; return }
        isLoading = true
        defer { isLoading = false }
        do {
            let dateStrings = dates.map { BlockDTO.dateFormatter.string(from: $0) }
            let userIdString = userId.uuidString.lowercased()

            print("DEBUG multi-date: fetching \(dateStrings.count) dates, userId=\(userIdString)")

            // Fetch owned blocks with exact date matches
            let exactDtos: [BlockWithSubBlocksDTO] = try await AppSupabase.client
                .from("blocks")
                .select("*, sub_blocks(*)")
                .in("date", value: dateStrings)
                .eq("user_id", value: userIdString)
                .order("start_time")
                .execute()
                .value

            // Fetch invited blocks for these dates
            let inviteStatuses = await fetchInviteStatuses(userId: userId)
            var invitedDtos: [BlockWithSubBlocksDTO] = []
            if !inviteStatuses.isEmpty {
                invitedDtos = try await AppSupabase.client
                    .from("blocks")
                    .select("*, sub_blocks(*)")
                    .in("date", value: dateStrings)
                    .in("id", value: Array(inviteStatuses.keys).map { $0.uuidString.lowercased() })
                    .order("start_time")
                    .execute()
                    .value
            }
            let allExactDtos = exactDtos + invitedDtos

            print("DEBUG multi-date: exactDtos=\(exactDtos.count), invitedDtos=\(invitedDtos.count)")

            // Fetch recurring blocks from before the date range (owned only)
            guard let earliestDate = dates.min() else { blocks = []; return }
            let earliestDateString = BlockDTO.dateFormatter.string(from: earliestDate)

            let recurringDtos: [BlockWithSubBlocksDTO] = try await AppSupabase.client
                .from("blocks")
                .select("*, sub_blocks(*)")
                .lt("date", value: earliestDateString)
                .neq("recurrence", value: "never")
                .eq("user_id", value: userIdString)
                .order("start_time")
                .execute()
                .value

            print("DEBUG multi-date: recurringDtos=\(recurringDtos.count), earliestDate=\(earliestDateString)")
            for dto in recurringDtos {
                print("DEBUG recurring: id=\(dto.id) title=\(dto.title) recurrence=\(dto.recurrence ?? "nil") date=\(dto.date)")
            }

            // Combine all recurring DTOs: from before the range AND within the range
            let allRecurring = recurringDtos + allExactDtos.filter {
                let rec = Recurrence(rawValue: $0.recurrence ?? "never") ?? .never
                return rec != .never
            }

            // For each recurring block, find which target dates it matches
            var expandedDtos: [(dto: BlockWithSubBlocksDTO, targetDate: Date)] = []

            // Add non-recurring exact matches with their own date
            for dto in allExactDtos {
                let rec = Recurrence(rawValue: dto.recurrence ?? "never") ?? .never
                if rec == .never, let date = BlockDTO.dateFormatter.date(from: dto.date) {
                    expandedDtos.append((dto, date))
                }
            }

            // Expand all recurring blocks across matching dates
            var seenRecurringIds = Set<UUID>()
            for dto in allRecurring {
                guard seenRecurringIds.insert(dto.id).inserted else { continue }
                guard let originDate = BlockDTO.dateFormatter.date(from: dto.date) else { continue }
                let recurrence = Recurrence(rawValue: dto.recurrence ?? "never") ?? .never
                let recurrenceEnd = dto.recurrenceEnd.flatMap { BlockDTO.dateFormatter.date(from: $0) }

                for targetDate in dates {
                    // Include the origin date itself, plus any recurrence matches
                    let isOrigin = Calendar.current.isDate(originDate, inSameDayAs: targetDate)
                    let isRecurrenceMatch = Self.recurrenceMatches(recurrence, originDate: originDate, targetDate: targetDate, exceptions: dto.exceptions ?? [], recurrenceEnd: recurrenceEnd)
                    if isOrigin || isRecurrenceMatch {
                        expandedDtos.append((dto, targetDate))
                    }
                }
            }

            // Process unique DTOs for sub-block hydration
            var seenIds = Set<UUID>()
            var uniqueDtos: [BlockWithSubBlocksDTO] = []
            for (dto, _) in expandedDtos {
                if seenIds.insert(dto.id).inserted {
                    uniqueDtos.append(dto)
                }
            }
            let hydratedBlocks = await processBlockDTOs(uniqueDtos)
            let blockById = Dictionary(uniqueKeysWithValues: hydratedBlocks.map { ($0.id, $0) })

            // Build final list with date-adjusted copies for recurring blocks
            var fetchedBlocks: [Block] = []
            var seenPairs = Set<String>()
            for (dto, targetDate) in expandedDtos {
                let pairKey = "\(dto.id)-\(BlockDTO.dateFormatter.string(from: targetDate))"
                guard seenPairs.insert(pairKey).inserted else { continue }
                guard var block = blockById[dto.id] else { continue }
                if !Calendar.current.isDate(block.startTime, inSameDayAs: targetDate) {
                    block = Self.adjustBlockToDate(block, targetDate: targetDate)
                }
                fetchedBlocks.append(block)
            }

            // Mark invited blocks as pending
            let pendingIds = Set(inviteStatuses.filter { $0.value == "pending" }.map { $0.key })
            markPendingBlocks(&fetchedBlocks, pendingIds: pendingIds)

            blocks = fetchedBlocks
        } catch {
            print("Error fetching blocks for multiple dates: \(error)")
        }
    }

    /// Fetches blocks for a set of dates and returns them without modifying `self.blocks`.
    /// Used by the monthly view to load months independently.
    func fetchBlocksWithoutStoring(for dates: [Date], userId: UUID) async -> [Block] {
        guard !dates.isEmpty else { return [] }
        do {
            let dateStrings = dates.map { BlockDTO.dateFormatter.string(from: $0) }
            let userIdString = userId.uuidString.lowercased()

            let exactDtos: [BlockWithSubBlocksDTO] = try await AppSupabase.client
                .from("blocks")
                .select("*, sub_blocks(*)")
                .in("date", value: dateStrings)
                .eq("user_id", value: userIdString)
                .order("start_time")
                .execute()
                .value

            // Fetch invited blocks for these dates
            let inviteStatuses = await fetchInviteStatuses(userId: userId)
            var invitedDtos: [BlockWithSubBlocksDTO] = []
            if !inviteStatuses.isEmpty {
                invitedDtos = try await AppSupabase.client
                    .from("blocks")
                    .select("*, sub_blocks(*)")
                    .in("date", value: dateStrings)
                    .in("id", value: Array(inviteStatuses.keys).map { $0.uuidString.lowercased() })
                    .order("start_time")
                    .execute()
                    .value
            }
            let allExactDtos = exactDtos + invitedDtos

            guard let earliestDate = dates.min() else { return [] }
            let earliestDateString = BlockDTO.dateFormatter.string(from: earliestDate)

            let recurringDtos: [BlockWithSubBlocksDTO] = try await AppSupabase.client
                .from("blocks")
                .select("*, sub_blocks(*)")
                .lt("date", value: earliestDateString)
                .neq("recurrence", value: "never")
                .eq("user_id", value: userIdString)
                .order("start_time")
                .execute()
                .value

            let allRecurring = recurringDtos + allExactDtos.filter {
                let rec = Recurrence(rawValue: $0.recurrence ?? "never") ?? .never
                return rec != .never
            }

            var expandedDtos: [(dto: BlockWithSubBlocksDTO, targetDate: Date)] = []

            for dto in allExactDtos {
                let rec = Recurrence(rawValue: dto.recurrence ?? "never") ?? .never
                if rec == .never, let date = BlockDTO.dateFormatter.date(from: dto.date) {
                    expandedDtos.append((dto, date))
                }
            }

            var seenRecurringIds = Set<UUID>()
            for dto in allRecurring {
                guard seenRecurringIds.insert(dto.id).inserted else { continue }
                guard let originDate = BlockDTO.dateFormatter.date(from: dto.date) else { continue }
                let recurrence = Recurrence(rawValue: dto.recurrence ?? "never") ?? .never
                let recurrenceEnd = dto.recurrenceEnd.flatMap { BlockDTO.dateFormatter.date(from: $0) }

                for targetDate in dates {
                    let isOrigin = Calendar.current.isDate(originDate, inSameDayAs: targetDate)
                    let isRecurrenceMatch = Self.recurrenceMatches(recurrence, originDate: originDate, targetDate: targetDate, exceptions: dto.exceptions ?? [], recurrenceEnd: recurrenceEnd)
                    if isOrigin || isRecurrenceMatch {
                        expandedDtos.append((dto, targetDate))
                    }
                }
            }

            var seenIds = Set<UUID>()
            var uniqueDtos: [BlockWithSubBlocksDTO] = []
            for (dto, _) in expandedDtos {
                if seenIds.insert(dto.id).inserted {
                    uniqueDtos.append(dto)
                }
            }
            let hydratedBlocks = await processBlockDTOs(uniqueDtos)
            let blockById = Dictionary(uniqueKeysWithValues: hydratedBlocks.map { ($0.id, $0) })

            var fetchedBlocks: [Block] = []
            var seenPairs = Set<String>()
            for (dto, targetDate) in expandedDtos {
                let pairKey = "\(dto.id)-\(BlockDTO.dateFormatter.string(from: targetDate))"
                guard seenPairs.insert(pairKey).inserted else { continue }
                guard var block = blockById[dto.id] else { continue }
                if !Calendar.current.isDate(block.startTime, inSameDayAs: targetDate) {
                    block = Self.adjustBlockToDate(block, targetDate: targetDate)
                }
                fetchedBlocks.append(block)
            }

            // Mark invited blocks as pending
            let pendingIds = Set(inviteStatuses.filter { $0.value == "pending" }.map { $0.key })
            markPendingBlocks(&fetchedBlocks, pendingIds: pendingIds)

            return fetchedBlocks
        } catch {
            print("Error fetching blocks for month: \(error)")
            return []
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

    // MARK: - Invitation Helpers

    /// Fetches all non-rejected invitation statuses for the current user.
    /// Returns a map of block ID → status ("pending" or "accepted").
    private func fetchInviteStatuses(userId: UUID) async -> [UUID: String] {
        do {
            let rows: [InvitationStatusDTO] = try await AppSupabase.client
                .from("event_invitees")
                .select("event_id, status")
                .eq("invitee_id", value: userId.uuidString.lowercased())
                .neq("status", value: "rejected")
                .execute()
                .value
            return Dictionary(uniqueKeysWithValues: rows.map { ($0.eventId, $0.status) })
        } catch {
            print("Error fetching invitation statuses: \(error)")
            return [:]
        }
    }

    /// Marks blocks that the user was invited to as pending.
    private func markPendingBlocks(_ blocks: inout [Block], pendingIds: Set<UUID>) {
        for i in blocks.indices {
            if pendingIds.contains(blocks[i].id) {
                blocks[i].isPending = true
            }
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

    /// If `end` is at or before `start` (e.g. user picked "12 AM" as the
    /// end time on the same day as a 10 PM start), roll `end` forward
    /// to the next day so the duration is positive.
    static func normalizeEndTime(start: Date, end: Date) -> Date {
        guard end <= start else { return end }
        return Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end
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
        let rawEnd = calendar.date(bySettingHour: endComps.hour ?? 0,
                                   minute: endComps.minute ?? 0,
                                   second: endComps.second ?? 0,
                                   of: targetDate) ?? block.endTime
        let newEnd = ModelData.normalizeEndTime(start: newStart, end: rawEnd)

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
    func createBlock(title: String, startTime: Date, endTime: Date, recurrence: Recurrence = .never, subBlocks: [SubBlock], userId: UUID) async -> UUID? {
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: startTime)
        let endTime = ModelData.normalizeEndTime(start: startTime, end: endTime)
        let blockId = UUID()

        let blockDTO = BlockDTO(
            id: blockId,
            userId: userId,
            title: title,
            date: BlockDTO.dateFormatter.string(from: date),
            startTime: BlockDTO.iso8601Formatter.string(from: startTime),
            endTime: BlockDTO.iso8601Formatter.string(from: endTime),
            status: "accepted",
            recurrence: recurrence.rawValue,
            exceptions: nil,
            recurrenceEnd: nil
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

            let newBlock = Block(
                id: blockId, date: date, startTime: startTime,
                endTime: endTime, title: title, recurrence: recurrence, subBlocks: subBlocks
            )
            blocks.append(newBlock)
            return blockId
        } catch {
            print("Error creating block: \(error)")
            return nil
        }
    }

    // MARK: - Invitation Actions

    /// Searches for app users by partial email match.
    func searchUsers(query: String) async -> [UserSearchResult] {
        let trimmed = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else { return [] }
        do {
            let results: [UserSearchResult] = try await AppSupabase.client
                .rpc("search_users_by_email", params: ["search_text": trimmed])
                .execute()
                .value
            return results
        } catch {
            print("DEBUG: User search error: \(error)")
            return []
        }
    }

    /// Inserts a new invitation record into the event_invitees table.
    func inviteUser(inviteeId: UUID, email: String, to blockId: UUID) async {
        let invite = EventInviteeDTO(
            event_id: blockId,
            invitee_id: inviteeId,
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

    /// Accepts an invitation by updating the event_invitees status to 'accepted'
    func acceptInvitation(blockId: UUID) async {
        do {
            try await AppSupabase.client
                .from("event_invitees")
                .update(["status": "accepted"])
                .eq("event_id", value: blockId.uuidString)
                .execute()

            if let index = blocks.firstIndex(where: { $0.id == blockId }) {
                blocks[index].isPending = false
            }
        } catch {
            print("Error accepting invitation: \(error)")
        }
    }

    /// Rejects an invitation by updating the event_invitees status to 'rejected'
    func rejectInvitation(blockId: UUID) async {
        do {
            try await AppSupabase.client
                .from("event_invitees")
                .update(["status": "rejected"])
                .eq("event_id", value: blockId.uuidString)
                .execute()

            blocks.removeAll { $0.id == blockId }
        } catch {
            print("Error rejecting invitation: \(error)")
        }
    }

    // MARK: - Update

    /// Updates an existing block in Supabase. Replaces all sub-blocks
    /// (deletes old ones, inserts new ones).
    func updateBlock(id: UUID, title: String, startTime: Date, endTime: Date, recurrence: Recurrence = .never, subBlocks: [SubBlock], userId: UUID) async {
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: startTime)
        let endTime = ModelData.normalizeEndTime(start: startTime, end: endTime)

        let blockDTO = BlockDTO(
            id: id,
            userId: userId,
            title: title,
            date: BlockDTO.dateFormatter.string(from: date),
            startTime: BlockDTO.iso8601Formatter.string(from: startTime),
            endTime: BlockDTO.iso8601Formatter.string(from: endTime),
            status: "accepted",
            recurrence: recurrence.rawValue,
            exceptions: nil,
            recurrenceEnd: nil
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


struct EventInviteeDTO: Encodable {
    let event_id: UUID
    let invitee_id: UUID
    let invitee_email: String
    let status: String
}

struct UserSearchResult: Codable, Identifiable {
    let id: UUID
    let email: String
}

private struct InvitationStatusDTO: Codable {
    let eventId: UUID
    let status: String

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case status
    }
}
