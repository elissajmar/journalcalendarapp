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
            if authController.isCheckingSession {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text("loading")
                        .font(.label)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "7A6559"))
            } else if authController.session != nil {
                ContentView()
                    .environment(modelData)
                    .environment(authController)
            } else {
                LoginView()
                    .environment(authController)
            }
        }
    }
}
