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

    let client = SupabaseClient(
        supabaseURL: URL(string: "https://wfxcwmpmixuvzcnzwgwn.supabase.co")!,
        supabaseKey: "sb_publishable_7dN3Rs6ebjcMOun8Z7HQ0Q_zHI0P8_p"
    )

    /// Fetches all events where the current user is the creator OR an invitee.
    func fetchMyCalendar() async throws -> [Event] {
        return try await client
            .from("events")
            .select()
            .order("start_time", ascending: true)
            .execute()
            .value
    }
}
