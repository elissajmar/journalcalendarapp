//
//  LoginView.swift
//  journalcalendar
//
//  Created by Claude on 4/1/26.
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthController.self) var auth
    
    enum Mode {
        case signIn, signUp
    }
    
    @State private var mode: Mode = .signUp
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showEmailConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Title
            Text(mode == .signUp ? "Let\u{2019}s get started" : "Welcome back")
                .font(.system(size: 28, weight: .regular, design: .serif))
                .padding(.bottom, 48)
            
            // Section label
            Text(mode == .signUp ? "CREATE AN ACCOUNT" : "SIGN IN")
                .font(.label)
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)
            
            // Form fields
            VStack(spacing: 0) {
                TextField("Youraddress@gmail.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.paragraph1)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 20)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                
                SecureField("Password", text: $password)
                    .textContentType(mode == .signUp ? .newPassword : .password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.paragraph1)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 20)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            
            // Error message
            if let errorMessage {
                Text(errorMessage)
                    .font(.label)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }
            
            // Email confirmation message
            if showEmailConfirmation {
                Text("Check your inbox for a confirmation email.")
                    .font(.label)
                    .foregroundStyle(.green)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }
            
            // Primary action button
            Button {
                Task { await primaryAction() }
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(mode == .signUp ? "Create account" : "Sign in")
                }
                .font(.label)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color(hex: "7A6559"))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(email.isEmpty || password.isEmpty || isLoading)
            .opacity((email.isEmpty || password.isEmpty) ? 0.5 : 1.0)
            .padding(.horizontal, 24)
            .padding(.top, 4)
            
            // OR divider
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                Text("OR")
                    .font(.label)
                    .foregroundStyle(.secondary)
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            
            // Social sign-in buttons (placeholders)
            VStack(spacing: 0) {
                socialButton(icon: "g.square.fill", label: "Sign in with Google")
                socialButton(icon: "apple.logo", label: "Sign in with Apple")
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Toggle mode
            Button {
                withAnimation {
                    mode = (mode == .signIn) ? .signUp : .signIn
                    errorMessage = nil
                    showEmailConfirmation = false
                }
            } label: {
                Text(mode == .signUp ? "SIGN IN TO EXISTING ACCOUNT" : "CREATE AN ACCOUNT")
                    .font(.label)
                    .foregroundStyle(.secondary)
                    .underline()
            }
            .padding(.bottom, 40)
        }
        .background(Color("AppBackground"))
    }
    
    // MARK: - Components
    
    private func socialButton(icon: String, label: String) -> some View {
        Button {
            // Placeholder for future implementation
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                Text(label)
                    .font(.paragraph1)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    // MARK: - Actions
    
    @MainActor
    private func primaryAction() async {
        isLoading = true
        errorMessage = nil
        showEmailConfirmation = false
        defer { isLoading = false }
        
        do {
            switch mode {
            case .signIn:
                try await auth.signIn(email: email, password: password)
            case .signUp:
                let needsConfirmation = try await auth.signUp(email: email, password: password)
                if needsConfirmation {
                    showEmailConfirmation = true
                }
            }
        } catch {
            errorMessage = mapAuthError(error)
        }
    }
    
    private func mapAuthError(_ error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        if message.contains("invalid login credentials") || message.contains("invalid_credentials") {
            return "Invalid email or password. Please try again."
        }
        if message.contains("user already registered") || message.contains("already_exists") {
            return "An account with this email already exists."
        }
        if message.contains("password") && message.contains("least") {
            return "Password must be at least 6 characters."
        }
        if message.contains("not authorized") || message.contains("email_not_confirmed") {
            return "Please confirm your email before signing in."
        }
        if message.contains("network") || message.contains("internet") {
            return "Network error. Please check your connection."
        }
        return "Something went wrong. Please try again."
    }
}

#Preview {
    LoginView()
        .environment(AuthController())
}
