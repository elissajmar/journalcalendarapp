//
//  AuthController.swift
//  journalcalendar
//
//  Created by Claude on 4/1/26.
//

import Foundation
import Supabase
import Auth

@MainActor
@Observable
final class AuthController {
    
    // MARK: - State
    
    /// The current session, or nil if signed out.
    var session: Session?
    
    /// True while the initial session check is in progress.
    var isCheckingSession = true
    
    /// The authenticated user's ID, or nil if not signed in.
    var currentUserId: UUID? {
        session?.user.id
    }
    
    // MARK: - Auth State Listener
    
    @ObservationIgnored
    private var authStateTask: Task<Void, Never>?
    
    init() {
        authStateTask = Task {
            for await (event, session) in AppSupabase.client.auth.authStateChanges {
                if [.initialSession, .signedIn, .signedOut].contains(event) {
                    self.session = session
                    
                    if event == .initialSession {
                        self.isCheckingSession = false
                    }
                }
            }
        }
    }
    
    deinit {
        authStateTask?.cancel()
    }
    
    // MARK: - Sign Up
    
    /// Creates a new account. Returns true if email confirmation is required.
    func signUp(email: String, password: String) async throws -> Bool {
        let response = try await AppSupabase.client.auth.signUp(
            email: email,
            password: password
        )
        // If session is nil, email confirmation is required
        return response.session == nil
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        try await AppSupabase.client.auth.signIn(
            email: email,
            password: password
        )
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        try await AppSupabase.client.auth.signOut()
    }
}
