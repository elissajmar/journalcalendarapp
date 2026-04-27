//
//  CalendarService.swift
//  journalcalendar
//
//  Created by Anushka R on 4/13/26.
//

import Foundation
import Supabase
import Observation

@Observable
class CalendarService {
    var events: [Event] = []
    var pendingInvites: [Invitation] = []
    
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://wfxcwmpmixuvzcnzwgwn.supabase.co")!,
        supabaseKey: "sb_publishable_7dN3Rs6ebjcMOun8Z7HQ0Q_zHI0P8_p"
    )

    /// Finds a user profile by their email address
    func findUser(email: String) async throws -> Profile? {
        return try await client
            .from("profiles")
            .select()
            .eq("email", value: email)
            .single()
            .execute()
            .value
    }

    /// Adds an invitee to a specific event by their email
    func addInvitee(eventId: UUID, email: String) async throws {
        // 1. Resolve the email to a user ID
        guard let profile = try await findUser(email: email) else {
            throw NSError(domain: "CalendarService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No user found with that email."])
        }
        
        // 2. Create the invite record
        let newInvite = EventInvitee(eventId: eventId, inviteeId: profile.id, status: "pending")
        
        // 3. Insert into the database
        try await client
            .from("event_invitees")
            .insert(newInvite)
            .execute()
    }

    /// Removes an invitee from an event
    func removeInvitee(eventId: UUID, userId: UUID) async throws {
        try await client
            .from("event_invitees")
            .delete()
            .eq("event_id", value: eventId)
            .eq("invitee_id", value: userId)
            .execute()
    }

    /// Fetches all events where the current user is the creator OR an invitee.
    /// Note: This relies on the PostgreSQL RLS policies being set up correctly.
    func fetchMyCalendar() async throws -> [Event] {
        return try await client
            .from("events")
            .select()
            .order("start_time", ascending: true)
            .execute()
            .value
    }
    
    func fetchPendingInvites(userId: UUID) async {
            do {
                // Fetch invites where status is 'pending'
                let invites: [Invitation] = try await AppSupabase.client
                    .from("event_invitees")
                    .select("*, blocks(*)") // Join with blocks to get event titles
                    .eq("invitee_id", value: userId.uuidString)
                    .eq("status", value: "pending")
                    .execute()
                    .value
                
                await MainActor.run {
                    self.pendingInvites = invites
                }
            } catch {
                print("Error fetching invites: \(error)")
            }
        }

        func updateInvitationStatus(eventId: UUID, userId: UUID, status: String) async throws {
            try await AppSupabase.client
                .from("event_invitees")
                .update(["status": status])
                .eq("event_id", value: eventId.uuidString)
                .eq("invitee_id", value: userId.uuidString)
                .execute()
            
            // Refresh the list locally
            await fetchPendingInvites(userId: userId)
        }
    }
    
    
    
//    func updateInvitationStatus(eventId: UUID, userId: UUID, status: String) async throws {
////        guard let userId = AuthController.shared.currentUserId else { return }
//        
//        try await AppSupabase.client
//            .from("event_invitees")
//            .update(["status": status])
//            .eq("event_id", value: eventId.uuidString)
//            .eq("invitee_id", value: userId.uuidString)
//            .execute()
//    }
//}
//
