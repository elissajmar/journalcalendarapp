//
//  SupabaseClient.swift
//  journalcalendar
//
//  Singleton Supabase client. Replace the placeholder URL and key
//  with your project's values from the Supabase Dashboard.
//

import Supabase

enum AppSupabase {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
        supabaseKey: "YOUR_SUPABASE_ANON_KEY"
    )
}
