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
    
    /// True once the initial auth state check has completed.
    /// Used to show a loading screen instead of a login flash on launch.
    var isReady: Bool = false
    
    /// The authenticated user's ID, or nil if not signed in.
    var currentUserId: UUID? {
        session?.user.id
    }
    
    // MARK: - Auth State Listener
    
    @ObservationIgnored
    private var authStateTask: Task<Void, Never>?
    
    init() {
        // Do NOT access AppSupabase.client synchronously here.
        // Doing so blocks the main thread with Supabase client init + keychain
        // access before the first UI frame even renders, causing visible startup lag.
        // Instead, defer all Supabase work into an async task so the UI appears
        // immediately. emitLocalSessionAsInitialSession:true ensures the cached
        // session is still delivered as the very first authStateChanges event.
        authStateTask = Task {
            // Yield once so the initial UI frame renders before Supabase initializes.
            await Task.yield()
            for await (event, session) in AppSupabase.client.auth.authStateChanges {
                if [.initialSession, .signedIn, .signedOut, .tokenRefreshed].contains(event) {
                    self.session = session
                    if !self.isReady { self.isReady = true }
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

    // MARK: - OAuth (Google / Apple)

    func signInWithOAuth(provider: Provider) async throws {
        try await AppSupabase.client.auth.signInWithOAuth(
            provider: provider,
            redirectTo: URL(string: "journalcalendar://login-callback")
        )
    }

    func signInWithGoogle() async throws {
        try await signInWithOAuth(provider: .google)
    }

    func signInWithApple() async throws {
        try await signInWithOAuth(provider: .apple)
    }
}
