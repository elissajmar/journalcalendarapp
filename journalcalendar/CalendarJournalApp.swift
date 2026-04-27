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
    @State var calendarService = CalendarService()

    var body: some Scene {
        WindowGroup {
            Group {
                if !authController.isReady {
                    // Show blank background while the auth check runs off the main thread.
                    // This prevents startup lag and avoids a login-screen flash for
                    // users who are already signed in.
                    Color("AppBackground").ignoresSafeArea()
                } else if authController.session != nil {
                    ContentView()
                        .environment(modelData)
                        .environment(authController)
                        .environment(calendarService)
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
