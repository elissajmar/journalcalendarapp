//
//  SupabaseClient.swift
//  journalcalendar
//
//  Singleton Supabase client. Replace the placeholder URL and key
//  with your project's values from the Supabase Dashboard.
//

import Foundation
import Supabase

enum AppSupabase {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://wfxcwmpmixuvzcnzwgwn.supabase.co")!,
        supabaseKey: "sb_publishable_7dN3Rs6ebjcMOun8Z7HQ0Q_zHI0P8_p",
        options: .init(auth: .init(emitLocalSessionAsInitialSession: true))
    )
}
