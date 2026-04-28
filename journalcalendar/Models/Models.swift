//
//  Models.swift
//  journalcalendar
//
//  Created by Anushka R on 4/13/26.
//

import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    let email: String
    let displayName: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case displayName = "display_name"
    }
}

struct Event: Codable, Identifiable {
    var id: UUID?
    let creatorId: UUID
    var title: String
    var description: String?
    var startTime: Date
    var endTime: Date

    enum CodingKeys: String, CodingKey {
        case id
        case creatorId = "creator_id"
        case title, description
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

struct EventInvitee: Codable {
    let eventId: UUID
    let inviteeId: UUID
    var status: String

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case inviteeId = "invitee_id"
        case status
    }
}

//struct EventInviteeDTO: Encodable {
//    let event_id: UUID
//    let invitee_email: String
//    let status: String
//}
