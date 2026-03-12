//
//  CalendarJournalApp.swift
//  Calendar Journal
//
//  Created on 3/11/26.
//

import SwiftUI
import SwiftData

@main
struct CalendarJournalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(ModelContainer.shared)
    }
}
