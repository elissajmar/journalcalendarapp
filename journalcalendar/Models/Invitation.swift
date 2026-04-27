//
//  Invitation.swift
//  journalcalendar
//
//  Created by Anushka R on 4/17/26.
//

import Foundation

struct Invitation: Identifiable, Codable {
    // This matches the 'event_invitees' table in Supabase
    let id: UUID
    let eventId: UUID
    let inviteeId: UUID
    let status: String
    
    // This property allows us to "join" and see the actual event details
    // It must match the name of the table you are joining in your .select() query
    let block: BlockDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case inviteeId = "invitee_id"
        case status
        case block = "blocks" // Supabase returns joined tables as an object/array
    }
}
