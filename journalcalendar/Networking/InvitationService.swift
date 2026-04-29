//
//  InvitationService.swift
//  journalcalendar
//
//  Handles all Supabase queries related to event invitations:
//  fetching statuses, resolving inviter emails, searching users,
//  and sending/accepting/rejecting invitations.
//

import Foundation

// MARK: - DTOs

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

// MARK: - Service

struct InvitationService {

    /// Fetches all non-rejected invitation statuses for the current user.
    /// Returns a map of block ID to status ("pending" or "accepted").
    static func fetchStatuses(userId: UUID) async -> [UUID: String] {
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

    /// Fetches the email of the block owner (inviter) for each invited block.
    static func fetchInviterEmails(for blockDtos: [BlockWithSubBlocksDTO]) async -> [UUID: String] {
        let ownerIds = Set(blockDtos.compactMap { $0.userId })
        guard !ownerIds.isEmpty else { return [:] }
        do {
            let profiles: [UserSearchResult] = try await AppSupabase.client
                .from("profiles")
                .select("id, email")
                .in("id", values: ownerIds.map { $0.uuidString.lowercased() })
                .execute()
                .value
            let emailById = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0.email) })
            var result: [UUID: String] = [:]
            for dto in blockDtos {
                if let userId = dto.userId, let email = emailById[userId] {
                    result[dto.id] = email
                }
            }
            return result
        } catch {
            print("Error fetching inviter emails: \(error)")
            return [:]
        }
    }

    /// Searches for app users by partial email match.
    static func searchUsers(query: String) async -> [UserSearchResult] {
        let trimmed = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else { return [] }
        do {
            let results: [UserSearchResult] = try await AppSupabase.client
                .rpc("search_users_by_email", params: ["search_text": trimmed])
                .execute()
                .value
            return results
        } catch {
            print("Error searching users: \(error)")
            return []
        }
    }

    /// Inserts a new invitation record into the event_invitees table.
    static func inviteUser(inviteeId: UUID, email: String, to blockId: UUID) async {
        let invite = EventInviteeDTO(
            event_id: blockId,
            invitee_id: inviteeId,
            invitee_email: email.lowercased().trimmingCharacters(in: .whitespaces),
            status: "pending"
        )
        do {
            try await AppSupabase.client
                .from("event_invitees")
                .insert(invite)
                .execute()
        } catch {
            print("Error inviting user: \(error)")
        }
    }

    /// Updates an invitation status to "accepted".
    static func accept(blockId: UUID) async throws {
        try await AppSupabase.client
            .from("event_invitees")
            .update(["status": "accepted"])
            .eq("event_id", value: blockId.uuidString)
            .execute()
    }

    /// Updates an invitation status to "rejected".
    static func reject(blockId: UUID) async throws {
        try await AppSupabase.client
            .from("event_invitees")
            .update(["status": "rejected"])
            .eq("event_id", value: blockId.uuidString)
            .execute()
    }
}
