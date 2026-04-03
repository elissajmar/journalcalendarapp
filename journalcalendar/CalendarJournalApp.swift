//
//  CalendarJournalApp.swift
//  Calendar Journal
//
//  Created on 3/11/26.
//

import SwiftUI
import Supabase

@main
struct CalendarJournalApp: App {
    @State private var authController = AuthController()
    @State private var modelData = ModelData()

    var body: some Scene {
        WindowGroup {
            Group {
                if authController.session != nil {
                    ContentView()
                        .environment(modelData)
                        .environment(authController)
                } else {
                    LoginView()
                        .environment(authController)
                }
            }
            .onChange(of: authController.session == nil) { _, isSignedOut in
                if isSignedOut {
                    modelData.blocks = []
                }
            }
        }
    }
}
